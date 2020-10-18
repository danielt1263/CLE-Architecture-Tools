//
//  Presenter.swift
//
//  Created by Daniel Tartaglia on 8/24/20.
//  Copyright © 2020 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift

extension UINavigationController {

	func push<T>(animated: Bool, scene: @autoclosure @escaping () -> (UIViewController, Observable<T>)) -> Observable<T> {
		observable(for: scene(), show: self.pusher(animated: animated), remove: self.popper(animated: animated))
	}

	func push<T, U>(animated: Bool, scene: @escaping (T) -> (UIViewController, Observable<U>)) -> AnyObserver<T> {
		observer(for: scene, show: self.pusher(animated: animated), remove: self.popper(animated: true))
	}

	func push<T>(animated: Bool, create: @escaping (T) -> UIViewController) -> AnyObserver<T> {
		observer(for: create, show: self.pusher(animated: animated))
	}

	func pusher(animated: Bool) -> (UIViewController) -> Void {
		return { [weak self] controller in
			self?.pushViewController(controller, animated: animated)
		}
	}

	func popper(animated: Bool) -> Completable {
		return Completable.create { [weak self] observer in
			self?.popViewController(animated: animated)
			observer(.completed)
			return Disposables.create()
		}
	}
}

extension UIViewController {

	func present<T>(animated: Bool, scene: @autoclosure @escaping () -> (UIViewController, Observable<T>)) -> Observable<T> {
		observable(for: scene(), show: self.presenter(animated: animated), remove: self.dismisser(animated: animated))
	}

	func present<T, U>(animated: Bool, scene: @escaping (T) -> (UIViewController, Observable<U>)) -> AnyObserver<T> {
		observer(for: scene, show: self.presenter(animated: animated), remove: self.dismisser(animated: true))
	}

	func present<T>(animated: Bool, create: @escaping (T) -> UIViewController) -> AnyObserver<T> {
		observer(for: create, show: self.presenter(animated: animated))
	}

	func presenter(animated: Bool) -> (UIViewController) -> Void {
		return { [weak self] controller in
			self?.present(controller, animated: animated, completion: nil)
		}
	}

	func dismisser(animated: Bool) -> Completable {
		return Completable.create { [unowned self] observer in
			if self.presentedViewController != nil {
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

func observable<T>(for scene: @autoclosure @escaping () -> (UIViewController, Observable<T>), show: @escaping (UIViewController) -> Void, remove: Completable) -> Observable<T> {
	return Observable.create { observer in
		let (controller, action) = scene()
		show(controller)
		return action
			.concat(remove.asObservable().map { $0 as! T })
			.subscribe(observer)
	}
}

func observer<T, U>(for scene: @escaping (T) -> (UIViewController, Observable<U>), show: @escaping (UIViewController) -> Void, remove: Completable) -> AnyObserver<T> {
	return AnyObserver { event in
		switch event {
		case .next(let value):
			let (controller, action) = scene(value)
			show(controller)
			_ = action.ignoreElements()
				.andThen(remove)
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

protocol Presentable {
}

extension Presentable where Self: UIViewController {
	static func scene<Action>(_ connect: (Self) -> Observable<Action>) -> (UIViewController, Observable<Action>) {
		let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
		let controller = storyboard.instantiateInitialViewController() as! Self
		return controller.scene(connect)
	}

	static func create(_ connect: (Self) -> Void) -> UIViewController {
		let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
		let controller = storyboard.instantiateInitialViewController() as! Self
		return controller.configure(connect)
	}

	func scene<Action>(_ connect: (Self) -> Observable<Action>) -> (UIViewController, Observable<Action>) {
		loadViewIfNeeded()
		return (self, connect(self))
	}

	func configure(_ connect: (Self) -> Void) -> UIViewController {
		loadViewIfNeeded()
		connect(self)
		return self
	}
}

extension UIAlertController: Presentable { }
extension UINavigationController: Presentable { }
extension UITabBarController: Presentable { }
