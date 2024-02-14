//
// Created by Daniel Tartgaglia on 19 Dec 2020.
// Copyright © 2023 Daniel Tartaglia. MIT License.
//

import Foundation
import RxCocoa
import RxSwift

public extension ObservableType {
	/**
	 Absorbs errors and routes them to the error router instead. If the source emits an error, this operator will
	 emit a completed event and the error router will emit the error as a next event.
	 - parameter errorRouter: The error router that will accept the error.
	 - returns: The source observable's events with an error event converted to a completed event.
	 */
	func rerouteError(_ errorRouter: ErrorRouter) -> Observable<Element> {
		errorRouter.rerouteError(self)
	}
}

public final class ErrorRouter {
	public let error: Observable<Error>
	private let _subject = PublishSubject<Error>()
	private let _lock = NSRecursiveLock()

	public init() {
		error = _subject.asObservable()
	}

	deinit {
		_lock.lock()
		_subject.onCompleted()
		_lock.unlock()
	}

	func routeError(_ error: Error) {
		_lock.lock()
		_subject.onNext(error)
		_lock.unlock()
	}

	fileprivate func rerouteError<O>(_ source: O) -> Observable<O.Element> where O: ObservableConvertibleType {
		source.asObservable()
			.observe(on: MainScheduler.instance)
			.catch { [self] error in
				self.routeError(error)
				return .empty()
			}
	}
}
