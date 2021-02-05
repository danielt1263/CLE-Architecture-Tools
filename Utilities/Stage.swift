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
public func presentScene<Action>(animated: Bool, overSourceView sourceView: UIView? = nil, scene: @escaping () -> Scene<Action>) -> Observable<Action> {
	presentScene(animated: animated, assignToPopover: assignToPopover(sourceView), scene: scene)
}

/**
Presents a scene onto the top view controller of the presentation stack. The scene will be dismissed when either the action observable completes/errors or is disposed.
- Parameters:
- animated: Pass `true` to animate the presentation; otherwise, pass `false`.
- barButtonItem:  If the scene will be presented in a popover controller, this is the barButtonItem that will serve as the focus.
- scene: A factory function for creating the Scene.
- Returns: The Scene's output action `Observable`.
*/
public func presentScene<Action>(animated: Bool, barButtonItem: UIBarButtonItem, scene: @escaping () -> Scene<Action>) -> Observable<Action> {
	presentScene(animated: animated, assignToPopover: assignToPopover(barButtonItem), scene: scene)
}

/**
Presents a scene onto the top view controller of the presentation stack. Can be used in a bind/subscribe/do onNext closure. The scene will dismiss when the action observable completes or errors.
- Parameters:
- animated: Pass `true` to animate the presentation; otherwise, pass `false`.
- sourceView: If the scene will be presented in a popover controller, this is the view that will serve as the focus.
- scene: A factory function for creating the Scene.
*/
public func finalPresentScene<Action>(animated: Bool, overSourceView sourceView: UIView? = nil, scene: @escaping () -> Scene<Action>) {
	_ = presentScene(animated: animated, overSourceView: sourceView, scene: scene)
		.subscribe()
}

/**
Push a scene onto a navigation constroller's stack. The scene will be popped when either the action observable completes/errors or is disposed.
- Parameter navigation: The navigation controller that scenes will be pushed onto.
- Returns: A function that will push the given scene with the given animation state and returns the scenes output action.
*/
public func pushScene<Action>(on navigation: UINavigationController) -> (_ animated: Bool, _ scene: @escaping () -> Scene<Action>) -> Observable<Action> {
	weak var nav = navigation
	return { animated, scene in
		nav!.pushScene(animated: animated, scene: scene)
	}
}

/**
Pushes a scene onto a navigation controller's stack. Can be used in a bind/subscribe/do onNext closure. The scene will be popped when the action observable completes or errors.
- Parameter navigation: The navigation controller that scenes will be pushed onto.
- Returns: A function that will push the given scene with the given animation state and returns the scenes output action.
*/
public func finalPushScene<Action>(on navigation: UINavigationController) -> (_ animated: Bool, _ scene: @escaping () -> Scene<Action>) -> Void {
	weak var nav = navigation
	return { animated, scene in
		nav!.finalPushScene(animated: animated, scene: scene)
	}
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
		Observable.deferred { [weak self] in
			let s = scene()
			let sharedAction = s.action.share()
			let top = self?.topViewController
			self?.pushViewController(s.controller, animated: animated)
			_ = sharedAction
				.subscribe(onDisposed: {
					if let top = top {
						self?.popToViewController(top, animated: animated)
					}
				})
			return sharedAction
		}
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

private let queue = DispatchQueue(label: "ScenePresentationHandler")

private func presentScene<Action>(animated: Bool, assignToPopover: @escaping (UIPopoverPresentationController) -> Void = { _ in }, scene: @escaping () -> Scene<Action>) -> Observable<Action> {
	Observable.deferred {
		let s = scene()
		weak var controller = s.controller
		show(controller: controller!, animated: animated, assignToPopover: assignToPopover)
		let sharedAction = s.action.share()
		_ = sharedAction
			.subscribe(onDisposed: {
				remove(child: controller, animated: animated)
			})
		return sharedAction
	}
}

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

private func remove(child: UIViewController?, animated: Bool) {
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
