//
//  UIViewController+Rx.swift
//  TCOMobile
//
//  Created by Daniel Tartaglia on 4/13/20.
//  Copyright © 2020 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UIViewController {
	var viewWillAppear: Observable<Bool> {
		return base.rx.methodInvoked(#selector(UIViewController.viewWillAppear(_:)))
			.map { $0[0] as! Bool }
	}

	var viewDidDisappear: Observable<Bool> {
		return base.rx.methodInvoked(#selector(UIViewController.viewDidDisappear(_:)))
			.map { $0[0] as! Bool }
	}

	func dismiss(animated: Bool) -> Observable<Void> {
		Observable.create { observer in
			self.base.dismiss(animated: animated, completion: {
				observer.onNext(())
				observer.onCompleted()
			})
			return Disposables.create()
		}
	}

	func dismissChild(animated: Bool) -> Observable<Void> {
		guard self.base.presentedViewController != nil else { return .just(()) }
		return self.base.rx.dismiss(animated: animated)
	}
}
