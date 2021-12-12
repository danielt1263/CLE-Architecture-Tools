//
//  ActivityTracker.swift
//
//  Created by Daniel Tartaglia on 05 Dec 2021.
//  Copyright © 2021 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

extension ObservableConvertibleType {
	/**
	 Attaches this Observable to the provided activity indicator object.
	 - Parameter activityIndicator: The ActivityIndicator that this observable should be attached
	 to.
	 - Returns: An Observable that forwards events from the source.
	 */
	public func trackActivity(_ activityTracker: ActivityTracker) -> Observable<Element> {
		activityTracker.trackActivity(of: self)
	}
}

/**
 Monitors the activity of all attached Observables. As long as any one attached Observable is active,
 `isActive` will emit `true`. Once all attached Observables have disposed, `isActive` will emit
 `false`.
 */
public final class ActivityTracker {
	public let isActive: Observable<Bool>

	private let subject = BehaviorSubject<Int>(value: 0)
	private let lock = NSRecursiveLock()

	public init() {
		isActive = subject
			.map { $0 > 0 }
			.distinctUntilChanged()
	}

	deinit {
		subject.onCompleted()
	}

	fileprivate func trackActivity<O>(of observable: O) -> Observable<O.Element> where O: ObservableConvertibleType {
		Observable.using(
			{ () -> AnyDisposable in
				self.increment()
				return AnyDisposable { self.decrement() }
			},
			observableFactory: { _ in observable.asObservable() }
		)
	}

	private func increment() {
		lock.lock()
		subject.onNext(try! subject.value() + 1)
		lock.unlock()
	}

	private func decrement() {
		lock.lock()
		subject.onNext(try! subject.value() - 1)
		lock.unlock()
	}
}

/**
 A generic Disposable object that will execute the provided closure when disposed.
 */
public final class AnyDisposable: Disposable {
	private let fn: () -> Void

	public init(_ fn: @escaping () -> Void) {
		self.fn = fn
	}

	public func dispose() {
		fn()
	}
}
