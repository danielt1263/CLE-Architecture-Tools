//
//  Scene.swift
//
//  Created by Daniel Tartaglia on 12/5/20.
//  Copyright © 2020 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift

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

	- Parameter connect: A function describing how the view controller should be connected and returning an Observable that emits any data the scene needs to communicate to its parent.
	- Parameter storyboardName: The name of the storyboard. If not supplied then the name of the view controller is assumed.
	- Parameter bundle: The bundle to look for the storyboard in. If not supplied then the system will look in the main bundle.
	- Returns: A Scene containing the view controller and return value of the connect function.

	Example:

	`let exampleScene = ExampleViewController.scene { $0.connect() }`
	*/
	static func scene<Action>(storyboardName: String = "", bundle: Bundle? = nil, identifier: String = "", _ connect: (Self) -> Observable<Action>) -> Scene<Action> {
		let storyboard = UIStoryboard(name: storyboardName.isEmpty ? String(describing: self) : storyboardName, bundle: bundle)
		let controller = identifier.isEmpty ? storyboard.instantiateInitialViewController() as! Self : storyboard.instantiateViewController(withIdentifier: identifier) as! Self
		return controller.scene(connect)
	}

	/**
	Extract an instance of this view controller out of a storyboard with the same name as it and cofigure it using the supplied connect function.

	- Parameter connect: A function describing how the view controller should be connected.
	- Parameter storyboardName: The name of the storyboard. If not supplied then the name of the view controller is assumed.
	- Parameter bundle: The bundle to look for the storyboard in. If not supplied then the system will look in the main bundle.
	- Returns: A configured view controller.

	Example:

	`let exampleViewController = ExampleViewController.create { $0.connect() }`
	*/
	static func create(storyboardName: String = "", bundle: Bundle? = nil, identifier: String = "", _ connect: (Self) -> Void) -> UIViewController {
		let storyboard = UIStoryboard(name: storyboardName.isEmpty ? String(describing: self) : storyboardName, bundle: bundle)
		let controller = identifier.isEmpty ? storyboard.instantiateInitialViewController() as! Self : storyboard.instantiateViewController(withIdentifier: identifier) as! Self
		return controller.configure(connect)
	}

	/**
	Create a scene from an already existing view controller.

	- Parameter connect: A function describing how the view controller should be connected and returning an Observable that emits any data the scene needs to communicate to its parent.
	- Returns: A Scene containing the view controller and return value of the connect function.

	Example:

	`let exampleScene = ExampleViewController().scene { $0.connect() }`
	*/
	func scene<Action>(_ connect: (Self) -> Observable<Action>) -> Scene<Action> {
		loadViewIfNeeded()
		return Scene(controller: self, action: connect(self))
	}

	/**
	Configure an existing view controller using the supplied connect function.

	- Parameter connect: A function describing how the view controller should be connected.
	- Returns: A configured view controller.

	Example:

	`let exampleViewController = ExampleViewController().create { $0.connect() }`
	*/
	func configure(_ connect: (Self) -> Void) -> UIViewController {
		loadViewIfNeeded()
		connect(self)
		return self
	}
}

public extension NSObjectProtocol {
	/**
	Can be used to setup a view controller before `viewDidLoad` is called. Can also be used to setup other UIKit objects.
	- Parameter fn: Closure that accepts the object.
	- Returns: The object.
	*/
	@discardableResult
	func setup(_ fn: (Self) -> Void) -> Self {
		fn(self)
		return self
	}
}
