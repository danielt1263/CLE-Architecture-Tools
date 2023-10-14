//
//  Scene.swift
//
//  Created by Daniel Tartaglia on 05 Dec 2020.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift
import RxCocoa

public struct Scene<Action> {
	public let controller: UIViewController
	public let action: Observable<Action>

	public init(controller: UIViewController, action: Observable<Action>) {
		self.controller = controller
		self.action = action
	}
}

/// shortcuts for creating scenes and view controllers.
public extension NSObjectProtocol where Self: UIViewController {
	/**
	Create a scene by reconstituting an instance of this view controller from a storyboard with the same name as it.

	- parameter connect: A function describing how the view controller should be connected and returning an Observable that emits any data the scene needs to communicate to its parent.
	- parameter storyboardName: The name of the storyboard. If not supplied then the name of the view controller is assumed.
	- parameter bundle: The bundle to look for the storyboard in. If not supplied then the system will look in the main bundle.
	- returns: A Scene containing the view controller and return value of the connect function.

	Example:

	`let exampleScene = ExampleViewController.scene { $0.connect() }`
	*/
	static func scene<Action>(storyboardName: String = "", bundle: Bundle? = nil, identifier: String = "", _ connect: @escaping (Self) -> Observable<Action>) -> Scene<Action> {
		let storyboard = UIStoryboard(name: storyboardName.isEmpty ? String(describing: self) : storyboardName, bundle: bundle)
		let controller = identifier.isEmpty ? storyboard.instantiateInitialViewController() as! Self : storyboard.instantiateViewController(withIdentifier: identifier) as! Self
		return controller.scene(connect)
	}

	/**
	Extract an instance of this view controller out of a storyboard with the same name as it and cofigure it using the supplied connect function.

	- parameter connect: A function describing how the view controller should be connected.
	- parameter storyboardName: The name of the storyboard. If not supplied then the name of the view controller is assumed.
	- parameter bundle: The bundle to look for the storyboard in. If not supplied then the system will look in the main bundle.
	- returns: A configured view controller.

	Example:

	`let exampleViewController = ExampleViewController.create { $0.connect() }`
	*/
	static func create(storyboardName: String = "", bundle: Bundle? = nil, identifier: String = "", _ connect: @escaping (Self) -> Void) -> UIViewController {
		let storyboard = UIStoryboard(name: storyboardName.isEmpty ? String(describing: self) : storyboardName, bundle: bundle)
		let controller = identifier.isEmpty ? storyboard.instantiateInitialViewController() as! Self : storyboard.instantiateViewController(withIdentifier: identifier) as! Self
		return controller.configure(connect)
	}

	/**
	Create a scene from an already existing view controller.

	- parameter connect: A function describing how the view controller should be connected and returning an Observable that emits any data the scene needs to communicate to its parent.
	- returns: A Scene containing the view controller and return value of the connect function.

	Example:

	`let exampleScene = ExampleViewController().scene { $0.connect() }`
	*/
	func scene<Action>(_ connect: @escaping (Self) -> Observable<Action>) -> Scene<Action> {
		let action = Observable.merge(rx.viewDidLoad, isViewLoaded ? .just(()) : .empty())
			.take(1)
			.flatMap { [weak self] () -> Observable<Action> in
				guard let self = self else { return .empty() }
				return connect(self)
			}
			.take(until: rx.deallocating)
			.publish()
		_ = action.connect()
		return Scene(controller: self, action: action)
	}

	/**
	Configure an existing view controller using the supplied connect function.

	- parameter connect: A function describing how the view controller should be connected.
	- returns: A configured view controller.

	Example:

	`let exampleViewController = ExampleViewController().create { $0.connect() }`
	*/
	func configure(_ connect: @escaping (Self) -> Void) -> UIViewController {
		_ = Observable.merge(rx.viewDidLoad, isViewLoaded ? .just(()) : .empty())
			.take(1)
			.take(until: rx.deallocating)
			.bind(with: self, onNext: { this, _ in connect(this) })
		return self
	}
}

public extension NSObjectProtocol {
	/**
	Can be used to setup a view controller before `viewDidLoad` is called. Can also be used to setup other UIKit objects.
	- parameter fn: Closure that accepts the object.
	- returns: The object.
	*/
	@discardableResult
	func setup(_ fn: (Self) -> Void) -> Self {
		fn(self)
		return self
	}
}
