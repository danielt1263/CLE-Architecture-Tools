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
- sourceView: If the scene will be presented in a popover controller, this is the view that will serve as the focus.
- scene: A factory function for creating the Scene.
- Returns: The Scene's output action `Observable`.
*/
public func presentScene<Action>(animated: Bool, over sourceView: UIView? = nil, scene: @escaping () -> Scene<Action>) -> Observable<Action> {
	Observable.using({ PresentationCoordinator(animated: animated, scene: scene(), assignToPopover: assignToPopover(sourceView)) }, observableFactory: { $0.action })
}

/**
Presents a scene onto the top view controller of the presentation stack. The scene will be dismissed when either the action observable completes/errors or is disposed.
- Parameters:
- animated: Pass `true` to animate the presentation; otherwise, pass `false`.
- barButtonItem:  If the scene will be presented in a popover controller, this is the barButtonItem that will serve as the focus.
- scene: A factory function for creating the Scene.
- Returns: The Scene's output action `Observable`.
*/
public func presentScene<Action>(animated: Bool, over barButtonItem: UIBarButtonItem, scene: @escaping () -> Scene<Action>) -> Observable<Action> {
	Observable.using({ PresentationCoordinator(animated: animated, scene: scene(), assignToPopover: assignToPopover(barButtonItem)) }, observableFactory: { $0.action })
}

/**
Presents a scene onto the top view controller of the presentation stack. Can be used in a bind/subscribe/do onNext closure. The scene will dismiss when the action observable completes or errors.
- Parameters:
- animated: Pass `true` to animate the presentation; otherwise, pass `false`.
- sourceView: If the scene will be presented in a popover controller, this is the view that will serve as the focus.
- scene: A factory function for creating the Scene.
*/
public func finalPresentScene<Action>(animated: Bool, over sourceView: UIView? = nil, scene: @escaping () -> Scene<Action>) {
	_ = presentScene(animated: animated, over: sourceView, scene: scene)
		.subscribe()
}

/**
Presents a scene onto the top view controller of the presentation stack. Can be used in a bind/subscribe/do onNext closure. The scene will dismiss when the action observable completes or errors.
- Parameters:
- animated: Pass `true` to animate the presentation; otherwise, pass `false`.
- barButtonItem:  If the scene will be presented in a popover controller, this is the barButtonItem that will serve as the focus.
- scene: A factory function for creating the Scene.
*/
public func finalPresentScene<Action>(animated: Bool, over barButtonItem: UIBarButtonItem, scene: @escaping () -> Scene<Action>) {
	_ = presentScene(animated: animated, over: barButtonItem, scene: scene)
		.subscribe()
}

public extension UINavigationController {
	/**
	Push a scene onto a navigation constroller's stack. The scene will be popped when either the action observable completes/errors or is disposed.
	- Parameters:
	- animated: Pass `true` to animate the presentation; otherwise, pass `false`.
	- scene: A factory function for creating the Scene.
	- Returns: The Scene's output action `Observable`.
	*/
	func pushScene<Action>(animated: Bool, scene: @escaping () -> Scene<Action>) -> Observable<Action> {
		Observable.using({ [weak self] in NavigationCoordinator(navigation: self, animated: animated, scene: scene()) }, observableFactory: { $0.action })
	}

	/**
	Pushes a scene onto a navigation controller's stack. Can be used in a bind/subscribe/do onNext closure. The scene will be popped when the action observable completes or errors.
	- Parameters:
	- animated: Pass `true` to animate the presentation; otherwise, pass `false`.
	- scene: A factory function for creating the Scene.
	*/
	func finalPushScene<Action>(animated: Bool, scene: @escaping () -> Scene<Action>) {
		_ = pushScene(animated: animated, scene: scene)
			.subscribe()
	}
}

private class PresentationCoordinator<Action>: Disposable {
	let action: Observable<Action>
	private weak var controller: UIViewController?
	private let animated: Bool

	init(animated: Bool, scene: Scene<Action>, assignToPopover: @escaping (UIPopoverPresentationController) -> Void = { _ in }) {
		self.controller = scene.controller
		self.action = scene.action
		self.animated = animated
		show(controller: scene.controller, animated: animated, assignToPopover: assignToPopover)
	}

	func dispose() {
		remove(child: controller, animated: animated)
	}
}

private class NavigationCoordinator<Action>: Disposable {
	let action: Observable<Action>
	private weak var navigation: UINavigationController?
	private weak var parent: UIViewController?
	private weak var controller: UIViewController?
	private let animated: Bool

	init(navigation: UINavigationController?, animated: Bool, scene: Scene<Action>) {
		self.action = scene.action
		self.navigation = navigation
		self.controller = scene.controller
		self.animated = animated
		queue.async { [weak navigation] in
			DispatchQueue.main.async {
				self.parent = navigation?.topViewController
				navigation?.pushViewController(scene.controller, animated: animated)
			}
		}
	}

	func dispose() {
		queue.async { [weak parent, weak navigation, animated] in
			DispatchQueue.main.async {
				if let parent = parent {
					navigation?.popToViewController(parent, animated: animated)
				}
			}
		}
	}
}

private let queue = DispatchQueue(label: "ScenePresentationHandler")

private func show(controller: UIViewController, animated: Bool, assignToPopover: @escaping (UIPopoverPresentationController) -> Void) {
	queue.async {
		let semaphore = DispatchSemaphore(value: 0)
		DispatchQueue.main.async {
			if let popoverPresentationController = controller.popoverPresentationController {
				assignToPopover(popoverPresentationController)
			}
			let top = UIViewController.top()
			top.present(controller, animated: animated, completion: {
				semaphore.signal()
			})
		}
		semaphore.wait()
	}
}

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

func remove(child: UIViewController?, animated: Bool) {
	queue.async { [weak child, animated] in
		let semaphore = DispatchSemaphore(value: 0)
		DispatchQueue.main.async {
			if let child = child, !child.isBeingDismissed {
				child.presentingViewController!.dismiss(animated: animated, completion: {
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
