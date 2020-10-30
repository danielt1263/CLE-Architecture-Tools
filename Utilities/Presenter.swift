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

// shortcuts for creating scenes and view controllers from storyboards.
extension Presentable where Self: UIViewController {
	static func scene<Action>(_ connect: (Self) -> Observable<Action>) -> Scene<Action> {
		let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
		let controller = storyboard.instantiateInitialViewController() as! Self
		return controller.scene(connect)
	}

	static func create(_ connect: (Self) -> Void) -> UIViewController {
		let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
		let controller = storyboard.instantiateInitialViewController() as! Self
		return controller.configure(connect)
	}

	func scene<Action>(_ connect: (Self) -> Observable<Action>) -> Scene<Action> {
		loadViewIfNeeded()
		return Scene(controller: self, action: connect(self))
	}

	func configure(_ connect: (Self) -> Void) -> UIViewController {
		loadViewIfNeeded()
		connect(self)
		return self
	}
}

// shortcuts for presenting view controllers from other view controllers.
extension UIViewController {

	func present<T>(animated: Bool, scene: @autoclosure @escaping () -> Scene<T>) -> Observable<T> {
		observable(for: scene(), show: self.presenter(animated: animated), remove: self.dismisser(animated: animated))
	}

	func present<T>(animated: Bool, popoverSource: UIView, scene: @autoclosure @escaping () -> Scene<T>) -> Observable<T> {
		observable(for: scene(), show: self.presenter(animated: animated, popoverSource: popoverSource), remove: self.dismisser(animated: animated))
	}

	func present<T, U>(animated: Bool, scene: @escaping (T) -> Scene<U>) -> AnyObserver<T> {
		observer(for: scene, show: self.presenter(animated: animated), remove: self.dismisser(animated: true))
	}

	func present<T>(animated: Bool, create: @escaping (T) -> UIViewController) -> AnyObserver<T> {
		observer(for: create, show: self.presenter(animated: animated))
	}
}

// shortcuts for pushing view controllers from other view controllers.
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
				if self.topViewController === controller {
					self.popViewController(animated: true)
				}
				return Disposables.create()
			}
		}
	}
}

extension UIViewController {

	func presenter(animated: Bool, popoverSource sourceView: UIView) -> (UIViewController) -> Void {
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
		return { [unowned self] in
			weak var controller = $0
			return Completable.create { observer in
				if self.presentedViewController === controller {
					self.dismiss(animated: animated) {
						observer(.completed)
					}
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

extension UIAlertController: Presentable { }
extension UINavigationController: Presentable { }
extension UITabBarController: Presentable { }
