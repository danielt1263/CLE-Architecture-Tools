//
//  Stage.swift
//
//  Created by Daniel Tartaglia on 24 Aug 2020.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import RxSwift
import UIKit

public extension UIViewController {
	/**
	 Presents a scene onto the top view controller of the presentation stack. The scene will be dismissed when either
	 the action observable completes/errors or is disposed.

	 - parameter self: The root view controller to present from. The system will move up the presentation stack from
	 here.
	 - parameter animated: Pass `true` to animate the presentation; otherwise, pass `false`.
	 - parameter sourceView: If the scene will be presented in a popover controller, this is the source view that will
	 serve as the focus.
	 - parameter scene: A factory function for creating the Scene.
	 - returns: A function that can be passed to `flatMap`, `flatMapFirst`, `flatMapLatest`, `concatMap` or can be
	 `subscribe`d to.
	 */
	func presentScene<Element, Action>(animated: Bool,
	                                   over sourceView: UIView? = nil,
	                                   scene: @escaping (Element) -> Scene<Action>) -> (Element) -> Observable<Action>
	{
		{ [weak self] element in
			Observable.using(
				{
					PresentationCoordinator(
						base: self,
						animated: animated,
						scene: scene(element),
						assignToPopover: sourceView.map { assignToPopover($0) }
					)
				},
				observableFactory: { $0.action }
			)
		}
	}

	/**
	 Presents a scene onto the top view controller of the presentation stack. The scene will be dismissed when either
	 the action observable completes/errors or is disposed.

	 - parameter self: The root view controller to present from. The system will move up the presentation stack from
	 here.
	 - parameter animated: Pass `true` to animate the presentation; otherwise, pass `false`.
	 - parameter barButtonItem: If the scene will be presented in a popover controller, this is the barButtonItem that
	 will serve as the focus.
	 - parameter scene: A factory function for creating the Scene.
	 - returns: A function that can be passed to `flatMap`, `flatMapFirst`, `flatMapLatest`, `concatMap` or can be
	 `subscribe`d to.
	 */
	func presentScene<Element, Action>(animated: Bool,
	                                   over barButtonItem: UIBarButtonItem,
	                                   scene: @escaping (Element) -> Scene<Action>)
		-> (Element) -> Observable<Action>
	{
		{ [weak self] element in
			Observable.using(
				{
					PresentationCoordinator(
						base: self,
						animated: animated,
						scene: scene(element),
						assignToPopover: assignToPopover(barButtonItem)
					)
				},
				observableFactory: { $0.action }
			)
		}
	}

	/**
	 Presents a scene onto the top view controller of the presentation stack. Can be used in a bind/subscribe/do onNext
	 closure. The scene will dismiss when the action observable completes or errors.

	 - parameter self: The root view controller to present from. The system will move up the presentation stack from
	 here.
	 - parameter animated: Pass `true` to animate the presentation; otherwise, pass `false`.
	 - parameter sourceView: If the scene will be presented in a popover controller, this is the view that will serve
	 as the focus.
	 - parameter scene: A factory function for creating the Scene.
	 - returns: A function that can be passed to the `onNext:` closure of `bind`, `subscribe` or `do`.
	 */
	func presentScene<Element, Action>(animated: Bool,
	                                   over sourceView: UIView? = nil,
	                                   scene: @escaping (Element) -> Scene<Action>) -> (Element) -> Void
	{
		{ [weak self] element in
			_ = self?.presentScene(animated: animated, over: sourceView, scene: scene)(element)
				.subscribe()
		}
	}

	/**
	 Presents a scene onto the top view controller of the presentation stack. Can be used in a bind/subscribe/do onNext
	 closure. The scene will dismiss when the action observable completes or errors.

	 - parameter self: The root view controller to present from. The system will move up the presentation stack from
	 here.
	 - parameter animated: Pass `true` to animate the presentation; otherwise, pass `false`.
	 - parameter barButtonItem:  If the scene will be presented in a popover controller, this is the barButtonItem that
	 will serve as the focus.
	 - parameter scene: A factory function for creating the Scene.
	 - returns: A function that can be passed to the `onNext:` closure of `bind`, `subscribe` or `do`.
	 */
	func presentScene<Element, Action>(animated: Bool,
	                                   over barButtonItem: UIBarButtonItem,
	                                   scene: @escaping (Element) -> Scene<Action>) -> (Element) -> Void
	{
		{ [weak self] element in
			_ = self?.presentScene(animated: animated, over: barButtonItem, scene: scene)(element)
				.subscribe()
		}
	}

	/**
	 Shows a scene from the top view controller of the presentation stack. If the scene is internally pushed onto a
	 navigation stack, the it will be popped when either the action observable completes/errors or is disposed.

	 - parameter self: The view controller to show from.
	 - parameter sender: The object that initiated the request.
	 - parameter scene: A factory function for creating the Scene.
	 - returns: A function that can be passed to `flatMap`, `flatMapFirst`, `flatMapLatest`, `concatMap` or can be
	 `subscribe`d to.
	 */
	func showScene<Element, Action>(sender: Any? = nil,
	                                scene: @escaping (Element) -> Scene<Action>)
		-> (Element) -> Observable<Action>
	{
		{ [weak self] element in
			Observable.using(
				{ ShowCoordinator(base: self, asDetail: false, sender: sender, scene: scene(element)) },
				observableFactory: { $0.action }
			)
		}
	}

	/**
	 Shows a scene from the top view controller of the presentation stack. If the scene is internally pushed onto a
	 navigation stack, the it will be popped when the action observable completes/errors.

	 - parameter self: The view controller to show from.
	 - parameter sender: The object that initiated the request.
	 - parameter scene:  A factory function for creating the Scene.
	 - returns: A function that can be passed to the `onNext:` closure of `bind`, `subscribe` or `do`.
	 */
	func showScene<Element, Action>(sender: Any? = nil,
	                                scene: @escaping (Element) -> Scene<Action>) -> (Element) -> Void
	{
		{ [weak self] element in
			_ = Observable.using(
				{ ShowCoordinator(base: self, asDetail: false, sender: sender, scene: scene(element)) },
				observableFactory: { $0.action }
			)
			.subscribe()
		}
	}

	/**
	 Shows a scene as a detail from the top view controller of the presentation stack. If the scene is internally
	 pushed onto a navigation stack, the it will be popped when either the action observable completes/errors or is
	 disposed.

	 - parameter self: The view controller to show from.
	 - parameter sender: The object that initiated the request.
	 - parameter scene:  A factory function for creating the Scene.
	 - returns: A function that can be passed to `flatMap`, `flatMapFirst`, `flatMapLatest`, `concatMap` or can be
	 `subscribe`d to.
	 */
	func showDetailScene<Element, Action>(sender: Any? = nil,
	                                      scene: @escaping (Element) -> Scene<Action>)
		-> (Element) -> Observable<Action>
	{
		{ [weak self] element in
			Observable.using(
				{ ShowCoordinator(base: self, asDetail: true, sender: sender, scene: scene(element)) },
				observableFactory: { $0.action }
			)
		}
	}

	/**
	 Shows a scene as a detail from the top view controller of the presentation stack. If the scene is internally
	 pushed onto a navigation stack, the it will be popped when either the action observable completes/errors.

	 - parameter self: The view controller to show from.
	 - parameter sender: The object that initiated the request.
	 - parameter scene:  A factory function for creating the Scene.
	 - returns: A function that can be passed to the `onNext:` closure of `bind`, `subscribe` or `do`.
	 */
	func showDetailScene<Element, Action>(sender: Any? = nil,
	                                      scene: @escaping (Element) -> Scene<Action>) -> (Element) -> Void
	{
		{ [weak self] element in
			_ = Observable.using(
				{ ShowCoordinator(base: self, asDetail: true, sender: sender, scene: scene(element)) },
				observableFactory: { $0.action }
			)
			.subscribe()
		}
	}
}

public extension UINavigationController {
	/**
	 Push a scene onto a navigation constroller's stack. The scene will be popped when either the action observable
	 completes/errors or is disposed.

	 - parameter self: The navigation controller to push onto.
	 - parameter animated: Pass `true` to animate the presentation; otherwise, pass `false`.
	 - parameter scene: A factory function for creating the Scene.
	 - returns: A function that can be passed to `flatMap`, `flatMapFirst`, `flatMapLatest`, `concatMap` or can be
	 `subscribe`d to.
	 */
	func pushScene<Element, Action>(animated: Bool,
	                                scene: @escaping (Element) -> Scene<Action>)
		-> (Element) -> Observable<Action>
	{
		{ [weak self] element in
			Observable.using(
				{ NavigationCoordinator(navigation: self, animated: animated, scene: scene(element)) },
				observableFactory: { $0.action }
			)
		}
	}

	/**
	 Pushes a scene onto a navigation controller's stack. Can be used in a bind/subscribe/do onNext closure. The scene
	 will be popped when the action observable completes or errors.

	 - parameter self: The navigation controller to push onto.
	 - parameter animated: Pass `true` to animate the presentation; otherwise, pass `false`.
	 - parameter scene: A factory function for creating the Scene.
	 - returns: A function that can be passed to the `onNext:` closure of `bind`, `subscribe` or `do`.
	 */
	func pushScene<Element, Action>(animated: Bool,
	                                scene: @escaping (Element) -> Scene<Action>) -> (Element) -> Void
	{
		{ [weak self] element in
			_ = Observable.using(
				{ NavigationCoordinator(navigation: self, animated: animated, scene: scene(element)) },
				observableFactory: { $0.action }
			)
			.subscribe()
		}
	}
}

@available(*, deprecated, message: "Use UINavigationController.pushScene(animated:scene:) instead")
public func pushScene<Element, Action>(on navigation: UINavigationController,
                                       animated: Bool,
                                       scene: @escaping (Element) -> Scene<Action>) -> (Element) -> Observable<Action>
{
	navigation.pushScene(animated: animated, scene: scene)
}

@available(*, deprecated, message: "Use UINavigationController.pushScene(animated:scene:) instead")
public func pushScene<Element, Action>(on navigation: UINavigationController,
                                       animated: Bool,
                                       scene: @escaping (Element) -> Scene<Action>) -> (Element) -> Void
{
	navigation.pushScene(animated: animated, scene: scene)
}

private final class PresentationCoordinator<Action>: Disposable {
	let action: Observable<Action>
	private weak var controller: UIViewController?
	private let animated: Bool

	init(base: UIViewController?,
	     animated: Bool,
	     scene: Scene<Action>,
	     assignToPopover: ((UIPopoverPresentationController) -> Void)?)
	{
		self.action = scene.action
			.do(
				onError: { [weak controller = scene.controller] _ in
					remove(controller: controller, animated: animated)
				},
				onCompleted: { [weak controller = scene.controller] in
					remove(controller: controller, animated: animated)
				}
			)
		self.controller = scene.controller
		self.animated = animated
		queue.async { [weak base] in
			let semaphore = DispatchSemaphore(value: 0)
			DispatchQueue.main.async {
				if let assignToPopover {
					scene.controller.modalPresentationStyle = .popover
					if let popoverPresentationController = scene.controller.popoverPresentationController {
						assignToPopover(popoverPresentationController)
					}
				}
				base?.topMost().present(scene.controller, animated: animated, completion: {
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
			.do(
				onError: { [weak controller = scene.controller] _ in pop(controller: controller, animated: animated) },
				onCompleted: { [weak controller = scene.controller] in pop(controller: controller, animated: animated) }
			)
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

	init(base: UIViewController?, asDetail: Bool, sender: Any? = nil, scene: Scene<Action>) {
		self.action = scene.action
		self.controller = scene.controller
		queue.async { [weak base] in
			DispatchQueue.main.async {
				let top = base?.topMost()
				if asDetail {
					top?.showDetailViewController(scene.controller, sender: sender)
				}
				else {
					top?.show(scene.controller, sender: sender)
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

private func assignToPopover(_ sourceView: UIView) -> (UIPopoverPresentationController) -> Void {
	{ popoverPresentationController in
		popoverPresentationController.sourceView = sourceView
		popoverPresentationController.sourceRect = sourceView.bounds
	}
}

func remove(controller: UIViewController?, animated: Bool) {
	queue.async { [weak controller, animated] in
		let semaphore = DispatchSemaphore(value: 0)
		DispatchQueue.main.async {
			if let parent = controller?.presentingViewController, controller!.isBeingDismissed == false {
				parent.dismiss(animated: animated, completion: {
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
			if let controller = controller,
			   let navigation = controller.navigationController,
			   let index = navigation.viewControllers.firstIndex(of: controller),
			   index > 0
			{
				navigation.popToViewController(navigation.viewControllers[index - 1], animated: true)
			}
		}
	}
}

private extension UIViewController {
	func topMost() -> UIViewController {
		var result = self
		while let vc = result.presentedViewController, !vc.isBeingDismissed {
			result = vc
		}
		return result
	}
}
