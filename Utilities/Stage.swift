//
//  Stage.swift
//
//  Created by Daniel Tartaglia on 8/24/20.
//  Copyright © 2020 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift

/**
 Presents a scene onto the top view controller of the presentation stack. The scene will be dismissed when either the action observable completes/errors or is disposed.
 - Parameters:
   - animated: Pass `true` to animate the presentation; otherwise, pass `false`.
   - sourceView: If the scene will be presented in a popover controller, this is the source view that will serve as the focus.
   - scene: A factory function for creating the Scene.
 - Returns: A function that can be passed to `flatMap`, `flatMapFirst`, `flatMapLatest`, `concatMap` or can be `subscribe`d to.
*/
public func presentScene<Element, Action>(animated: Bool, over sourceView: UIView? = nil, scene: @escaping (Element) -> Scene<Action>) -> (Element) -> Observable<Action> {
	{ element in
		Observable.using({ PresentationCoordinator(animated: animated, scene: scene(element), assignToPopover: assignToPopover(sourceView)) }, observableFactory: { $0.action })
	}
}

/**
 Presents a scene onto the top view controller of the presentation stack. The scene will be dismissed when either the action observable completes/errors or is disposed.
 - Parameters:
   - animated: Pass `true` to animate the presentation; otherwise, pass `false`.
   - barButtonItem: If the scene will be presented in a popover controller, this is the barButtonItem that will serve as the focus.
   - scene: A factory function for creating the Scene.
 - Returns: A function that can be passed to `flatMap`, `flatMapFirst`, `flatMapLatest`, `concatMap` or can be `subscribe`d to.
*/
public func presentScene<Element, Action>(animated: Bool, over barButtonItem: UIBarButtonItem, scene: @escaping (Element) -> Scene<Action>) -> (Element) -> Observable<Action> {
	{ element in
		Observable.using({ PresentationCoordinator(animated: animated, scene: scene(element), assignToPopover: assignToPopover(barButtonItem)) }, observableFactory: { $0.action })
	}
}

/**
 Presents a scene onto the top view controller of the presentation stack. Can be used in a bind/subscribe/do onNext closure. The scene will dismiss when the action observable completes or errors.
 - Parameters:
   - animated: Pass `true` to animate the presentation; otherwise, pass `false`.
   - sourceView: If the scene will be presented in a popover controller, this is the view that will serve as the focus.
   - scene: A factory function for creating the Scene.
 - Returns: A function that can be passed to the `onNext:` closure of `bind`, `subscribe` or `do`.
*/
public func presentScene<Element, Action>(animated: Bool, over sourceView: UIView? = nil, scene: @escaping (Element) -> Scene<Action>) -> (Element) -> Void {
	{ element in
		_ = presentScene(animated: animated, over: sourceView, scene: scene)(element)
			.subscribe()
	}
}

/**
 Presents a scene onto the top view controller of the presentation stack. Can be used in a bind/subscribe/do onNext closure. The scene will dismiss when the action observable completes or errors.
 - Parameters:
   - animated: Pass `true` to animate the presentation; otherwise, pass `false`.
   - barButtonItem:  If the scene will be presented in a popover controller, this is the barButtonItem that will serve as the focus.
   - scene: A factory function for creating the Scene.
 - Returns: A function that can be passed to the `onNext:` closure of `bind`, `subscribe` or `do`.
*/
public func presentScene<Element, Action>(animated: Bool, over barButtonItem: UIBarButtonItem, scene: @escaping (Element) -> Scene<Action>) -> (Element) -> Void {
	{ element in
		_ = presentScene(animated: animated, over: barButtonItem, scene: scene)(element)
			.subscribe()
	}
}

/**
 Shows a scene from the top view controller of the presentation stack. If the scene is internally pushed onto a navigation stack, the it will be popped when either the action observable completes/errors or is disposed.
 - Parameters:
   - sender: The object that initiated the request.
   - scene: A factory function for creating the Scene.
 - Returns: A function that can be passed to `flatMap`, `flatMapFirst`, `flatMapLatest`, `concatMap` or can be `subscribe`d to.
*/
public func showScene<Element, Action>(sender: Any? = nil, scene: @escaping (Element) -> Scene<Action>) -> (Element) -> Observable<Action> {
	{ element in
		Observable.using({ ShowCoordinator(asDetail: false, sender: sender, scene: scene(element)) }, observableFactory: { $0.action })
	}
}

/**
 Shows a scene from the top view controller of the presentation stack. If the scene is internally pushed onto a navigation stack, the it will be popped when the action observable completes/errors.
 - Parameters:
   - sender: The object that initiated the request.
   - scene:  A factory function for creating the Scene.
 - Returns: A function that can be passed to the `onNext:` closure of `bind`, `subscribe` or `do`.
*/
public func showScene<Element, Action>(sender: Any? = nil, scene: @escaping (Element) -> Scene<Action>) -> (Element) -> Void {
	{ element in
		_ = Observable.using({ ShowCoordinator(asDetail: false, sender: sender, scene: scene(element)) }, observableFactory: { $0.action })
			.subscribe()
	}
}

/**
 Shows a scene as a detail from the top view controller of the presentation stack. If the scene is internally pushed onto a navigation stack, the it will be popped when either the action observable completes/errors or is disposed.
 - Parameters:
   - sender: The object that initiated the request.
   - scene:  A factory function for creating the Scene.
 - Returns: A function that can be passed to `flatMap`, `flatMapFirst`, `flatMapLatest`, `concatMap` or can be `subscribe`d to.
*/
public func showDetailScene<Element, Action>(sender: Any? = nil, scene: @escaping (Element) -> Scene<Action>) -> (Element) -> Observable<Action> {
	{ element in
		Observable.using({ ShowCoordinator(asDetail: true, sender: sender, scene: scene(element)) }, observableFactory: { $0.action })
	}
}

/**
 Shows a scene as a detail from the top view controller of the presentation stack. If the scene is internally pushed onto a navigation stack, the it will be popped when either the action observable completes/errors.
 - Parameters:
   - sender: The object that initiated the request.
   - scene:  A factory function for creating the Scene.
 - Returns: A function that can be passed to the `onNext:` closure of `bind`, `subscribe` or `do`.
*/
public func showDetailScene<Element, Action>(sender: Any? = nil, scene: @escaping (Element) -> Scene<Action>) -> (Element) -> Void {
	{ element in
		_ = Observable.using({ ShowCoordinator(asDetail: true, sender: sender, scene: scene(element)) }, observableFactory: { $0.action })
			.subscribe()
	}
}

/**
 Push a scene onto a navigation constroller's stack. The scene will be popped when either the action observable completes/errors or is disposed.
 - Parameters:
   - animated: Pass `true` to animate the presentation; otherwise, pass `false`.
   - scene: A factory function for creating the Scene.
 - Returns: A function that can be passed to `flatMap`, `flatMapFirst`, `flatMapLatest`, `concatMap` or can be `subscribe`d to.
*/
public func pushScene<Element, Action>(on navigation: UINavigationController, animated: Bool, scene: @escaping (Element) -> Scene<Action>) -> (Element) -> Observable<Action> {
	{ element in
		Observable.using({ [weak navigation] in NavigationCoordinator(navigation: navigation, animated: animated, scene: scene(element)) }, observableFactory: { $0.action })
	}
}

/**
 Pushes a scene onto a navigation controller's stack. Can be used in a bind/subscribe/do onNext closure. The scene will be popped when the action observable completes or errors.
 - Parameters:
   - animated: Pass `true` to animate the presentation; otherwise, pass `false`.
   - scene: A factory function for creating the Scene.
 - Returns: A function that can be passed to the `onNext:` closure of `bind`, `subscribe` or `do`.
*/
public func pushScene<Element, Action>(on navigation: UINavigationController, animated: Bool, scene: @escaping (Element) -> Scene<Action>) -> (Element) -> Void {
	{ element in
		_ = Observable.using({ [weak navigation] in NavigationCoordinator(navigation: navigation, animated: animated, scene: scene(element)) }, observableFactory: { $0.action })
			.subscribe()
	}
}

private final class PresentationCoordinator<Action>: Disposable {
	let action: Observable<Action>
	private weak var controller: UIViewController?
	private let animated: Bool

	init(animated: Bool, scene: Scene<Action>, assignToPopover: @escaping (UIPopoverPresentationController) -> Void = { _ in }) {
		self.controller = scene.controller
		self.action = scene.action
		self.animated = animated
		queue.async {
			let semaphore = DispatchSemaphore(value: 0)
			DispatchQueue.main.async {
				if let popoverPresentationController = scene.controller.popoverPresentationController {
					assignToPopover(popoverPresentationController)
				}
				UIViewController.top().present(scene.controller, animated: animated, completion: {
					semaphore.signal()
				})
			}
			semaphore.wait()
		}
	}

	func dispose() {
		remove(controller: controller, animated: animated)
	}
}

private final class NavigationCoordinator<Action>: Disposable {
	let action: Observable<Action>
	private weak var controller: UIViewController?
	private let animated: Bool

	init(navigation: UINavigationController?, animated: Bool, scene: Scene<Action>) {
		self.action = scene.action
		self.controller = scene.controller
		self.animated = animated
		queue.async { [weak navigation] in
			DispatchQueue.main.async {
				navigation?.pushViewController(scene.controller, animated: animated)
			}
		}
	}

	func dispose() {
		pop(controller: controller, animated: animated)
	}
}

private final class ShowCoordinator<Action>: Disposable {
	let action: Observable<Action>
	weak var controller: UIViewController?

	init(asDetail: Bool, sender: Any? = nil, scene: Scene<Action>) {
		action = scene.action
		controller = scene.controller
		queue.async {
			DispatchQueue.main.async {
				let top = UIViewController.top()
				if asDetail {
					top.showDetailViewController(scene.controller, sender: sender)
				}
				else {
					top.show(scene.controller, sender: sender)
				}
			}
		}
	}

	func dispose() {
		pop(controller: controller, animated: true)
	}
}

private let queue = DispatchQueue(label: "ScenePresentationHandler")

private func assignToPopover(_ barButtonItem: UIBarButtonItem) -> (UIPopoverPresentationController) -> Void {
	{ popoverPresentationController in
		popoverPresentationController.barButtonItem = barButtonItem
	}
}

private func assignToPopover(_ sourceView: UIView?) -> (UIPopoverPresentationController) -> Void {
	{ popoverPresentationController in
		if let sourceView = sourceView {
			popoverPresentationController.sourceView = sourceView
			popoverPresentationController.sourceRect = sourceView.bounds
		}
	}
}

func remove(controller: UIViewController?, animated: Bool) {
	queue.async { [weak controller, animated] in
		let semaphore = DispatchSemaphore(value: 0)
		DispatchQueue.main.async {
			if let controller = controller, !controller.isBeingDismissed {
				controller.presentingViewController!.dismiss(animated: animated, completion: {
					semaphore.signal()
				})
			}
			else {
				semaphore.signal()
			}
		}
		semaphore.wait()
	}
}

func pop(controller: UIViewController?, animated: Bool) {
	queue.async { [weak controller] in
		DispatchQueue.main.async {
			if let controller = controller, let navigation = controller.navigationController, let index = navigation.viewControllers.firstIndex(of: controller), index > 0 {
				navigation.popToViewController(navigation.viewControllers[index - 1], animated: true)
			}
		}
	}
}

private extension UIViewController {
	static func top() -> UIViewController {
		guard let rootViewController = UIApplication.shared.delegate?.window??.rootViewController else { fatalError("No view controller present in app?") }
		var result = rootViewController
		while let vc = result.presentedViewController, !vc.isBeingDismissed {
			result = vc
		}
		return result
	}
}
