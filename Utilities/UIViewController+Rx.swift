//
//  UIViewController+Rx.swift
//
//  Created by Daniel Tartaglia on 4/13/20.
//  Copyright © 2020 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift
import RxCocoa

public extension Reactive where Base: UIViewController {

	var viewWillAppear: Observable<Bool> {
		return base.rx.methodInvoked(#selector(UIViewController.viewWillAppear(_:)))
			.map { $0[0] as! Bool }
	}

	var viewDidDisappear: Observable<Bool> {
		return base.rx.methodInvoked(#selector(UIViewController.viewDidDisappear(_:)))
			.map { $0[0] as! Bool }
	}

	/// Can be used to dismiss the view controller if you want to do it before the scene's action disposes.
	/// - Parameter animated: Pass true to animate the transition.
	/// - Returns: A trigger Observable to notify you that it's done.
	func dismissSelf(animated: Bool) -> Observable<Void> {
		Observable.deferred { [base] in
			remove(controller: base, animated: animated)
			return Observable.just(())
		}
	}

	/// Can be used to pop the view controller if you want to do it before the scene's action disposes. If the view controller wasn't pushed, then this does nothing.
	/// - Parameter animated: Set this value to true to animate the transition. Pass false if you are setting up a navigation controller before its view is displayed.
	/// - Returns: A trigger Observable to notify you that it's done.
	func popSelf(animated: Bool) -> Observable<Void> {
		Observable.deferred { [base] in
			pop(controller: base, animated: animated)
			return Observable.just(())
		}
	}
}
