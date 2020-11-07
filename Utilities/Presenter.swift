//
//  Presenter.swift
//
//  Created by Daniel Tartaglia on 8/24/20.
//  Copyright © 2020 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift

struct Scene<Action> {
	let controller: UIViewController
	let action: Observable<Action>
}

/// shortcuts for creating scenes and view controllers.
extension Presentable where Self: UIViewController {
	/**
	Create a scene by reconstituting an instance of this view controller from a storyboard with the same name as it.

	- Parameter connect: A function describing how the view controller should be connected and returning an Observable that emits any data the scene needs to communicate to its parent.
	- Returns: A Scene containing the view controller and return value of the connect function.

	Example:

	`let exampleScene = ExampleViewController.scene { $0.connect() }`
	*/
	static func scene<Action>(_ connect: (Self) -> Observable<Action>) -> Scene<Action> {
		let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
		let controller = storyboard.instantiateInitialViewController() as! Self
		return controller.scene(connect)
	}

	/**
	Extract an instance of this view controller out of a storyboard with the same name as it and cofigure it using the supplied connect function.

	- Parameter connect: A function describing how the view controller should be connected.
	- Returns: A configured view controller.

	Example:

	`let exampleViewController = ExampleViewController.create { $0.connect() }`
	*/
	static func create(_ connect: (Self) -> Void) -> UIViewController {
		let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
		let controller = storyboard.instantiateInitialViewController() as! Self
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

/// shortcuts for presenting view controllers from other view controllers.
extension UIViewController {

	/**
	Present a scene on this view controller. The scene will not be created until needed and its view controller will be dismissed when the action observable completes.

	- Parameters:
	- animated: Should the view controller present/dismiss in an animated style?
	- scene: The scene that should be presented.
	- Returns: The action observable of the scene.

	Example:

	```
	someObservable
	.flatMapFirst { [unowned self] someData in
		self.present(animated: true, scene: ExampleViewController().scene { $0.connect(initialData: someData) })
	}
	```
	*/
	func present<T>(animated: Bool, scene: @autoclosure @escaping () -> Scene<T>) -> Observable<T> {
		observable(for: scene(), show: self.presenter(animated: animated), remove: self.dismisser(animated: animated))
	}

	/**
	Present a scene on this view controller in a popover if on iPad. The scene will not be created until needed and its view controller will be dismissed when the action observable completes.

	- Parameters:
	- animated: Should the view controller present/dismiss in an animated style?
	- scene: The scene that should be presented.
	- Returns: The action observable of the scene.

	Example:

	```
	someObservable
	.flatMapFirst { [unowned self, unowned myButton] someData in
		self.present(animated: true, overSourceView: myButton, scene: ExampleViewController().scene { $0.connect(initialData: someData) })
	}
	```
	*/
	func present<T>(animated: Bool, overSourceView sourceView: UIView, scene: @autoclosure @escaping () -> Scene<T>) -> Observable<T> {
		observable(for: scene(), show: self.presenter(animated: animated, overSourceView: sourceView), remove: self.dismisser(animated: animated))
	}

	/**
	Create an Observer that will present a scene on this view controller when it receives a value. The scene will not be created until needed and its view controller will be dismissed when the action observable completes. Any next events emitted from the action will be ignored.

	- Parameters:
	- animated: Should the view controller present/dismiss in an animated style?
	- scene: The scene that should be presented.
	- Returns: The action observable of the scene.

	Example:

	```
	someObservable
		.bind(to: present(animated: true) { someData in
			ExampleViewController().scene { $0.connect(initialData: someData) }
		})
	}
	```
	*/
	func present<T, U>(animated: Bool, scene: @escaping (T) -> Scene<U>) -> AnyObserver<T> {
		observer(for: scene, show: self.presenter(animated: animated), remove: self.dismisser(animated: true))
	}

	/**
	Create an Observer that will present a view controller on this view controller when it receives a value. The view controller must handle its own dismissal.

	- Parameters:
	- animated: Should the view controller present/dismiss in an animated style?
	- scene: The scene that should be presented.
	- Returns: The action observable of the scene.

	Example:

	```
	someObservable
		.bind(to: present(animated: true) { someData in
			ExampleViewController().configure { $0.connect(initialData: someData) }
		})
	}
	```
	*/
	func present<T>(animated: Bool, create: @escaping (T) -> UIViewController) -> AnyObserver<T> {
		observer(for: create, show: self.presenter(animated: animated))
	}
}

/// shortcuts for pushing view controllers from other view controllers.
extension UINavigationController {

	func push<T>(animated: Bool, scene: @autoclosure @escaping () -> Scene<T>) -> Observable<T> {
		observable(for: scene(), show: self.pusher(animated: animated), remove: self.popper(animated: animated))
	}

	func push<T, U>(animated: Bool, scene: @escaping (T) -> Scene<U>) -> AnyObserver<T> {
		observer(for: scene, show: self.pusher(animated: animated), remove: self.popper(animated: true))
	}

	func push<T>(animated: Bool, create: @escaping (T) -> UIViewController) -> AnyObserver<T> {
		observer(for: create, show: self.pusher(animated: animated))
	}
}

extension UINavigationController {
	func pusher(animated: Bool) -> (UIViewController) -> Void {
		return { [weak self] controller in
			self?.pushViewController(controller, animated: animated)
		}
	}

	func popper(animated: Bool) -> (UIViewController) -> Completable {
		return { [unowned self] in
			weak var controller = $0
			return Completable.create { observer in
				if let position = self.viewControllers.firstIndex(where: { $0 === controller }), position > 0 {
					self.popToViewController(self.viewControllers[position - 1], animated: animated)
				}
				return Disposables.create()
			}
		}
	}
}

extension UIViewController {

	func presenter(animated: Bool, overSourceView sourceView: UIView) -> (UIViewController) -> Void {
		return { [weak self] controller in
			if let popoverPresentationController = controller.popoverPresentationController {
				popoverPresentationController.sourceView = sourceView
				popoverPresentationController.sourceRect = sourceView.bounds
			}
			self?.present(controller, animated: animated, completion: nil)
		}
	}

	func presenter(animated: Bool) -> (UIViewController) -> Void {
		return { [weak self] controller in
			self?.present(controller, animated: animated, completion: nil)
		}
	}

	func dismisser(animated: Bool) -> (UIViewController) -> Completable {
		return {
			weak var controller = $0
			return Completable.create { observer in
				if let parent = controller?.presentingViewController {
					parent.dismiss(animated: animated) {
						observer(.completed)
					}
				}
				else if let this = controller {
					this.dismiss(animated: true, completion: {
						observer(.completed)
					})
				}
				else {
					observer(.completed)
				}
				return Disposables.create()
			}
		}
	}
}

func observable<T>(for scene: @autoclosure @escaping () -> Scene<T>, show: @escaping (UIViewController) -> Void, remove: @escaping (UIViewController) -> Completable) -> Observable<T> {
	return Observable.create { observer in
		assert(Thread.current == .main)
		let scene = scene()
		show(scene.controller)
		return scene.action
			.observeOn(MainScheduler.instance)
			.concat(remove(scene.controller).asObservable().map { $0 as! T })
			.subscribe(observer)
	}
}

func observer<T, U>(for scene: @escaping (T) -> Scene<U>, show: @escaping (UIViewController) -> Void, remove: @escaping (UIViewController) -> Completable) -> AnyObserver<T> {
	return AnyObserver { event in
		assert(Thread.current == .main)
		switch event {
		case .next(let value):
			let scene = scene(value)
			show(scene.controller)
			_ = scene.action.ignoreElements()
				.observeOn(MainScheduler.instance)
				.andThen(remove(scene.controller))
				.subscribe()
		case .error(let error):
			let description = "Binding error: \(error)"
			#if DEBUG
			fatalError(description)
			#else
			print(description)
			#endif
		case .completed:
			break
		}
	}
}

func observer<T>(for create: @escaping (T) -> UIViewController, show: @escaping (UIViewController) -> Void) -> AnyObserver<T> {
	return AnyObserver { event in
		switch event {
		case .next(let value):
			show(create(value))
		case .error(let error):
			let description = "Binding error: \(error)"
			#if DEBUG
			fatalError(description)
			#else
			print(description)
			#endif
		case .completed:
			break
		}
	}
}

protocol Presentable { }
extension UIViewController: Presentable { }
