//
// Created by Daniel Tartgaglia on 12/19/2020.
// Copyright (c) 2020 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift
import RxCocoa

extension ObservableType {
	/// Absorbs errors and routes them to the error router instead. If the source emits an error, this operator will emit a completed event and the error router will emit the error as a next event.
	/// - Parameter errorRouter: The error router that will accept the error.
	/// - Returns: The source observable's events with an error event converted to a completed event.
	public func rerouteError(_ errorRouter: ErrorRouter) -> Observable<Element> {
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

	fileprivate func rerouteError<O>(_ source: O) -> Observable<O.Element> where O: ObservableConvertibleType {
		source.asObservable()
			.observe(on: MainScheduler.instance)
			.catch { [_lock, _subject] error in
				_lock.lock()
				_subject.onNext(error)
				_lock.unlock()
				return .empty()
			}
	}
}
