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

	public init() {
		error = _subject.asObservable()
	}

	deinit {
		_subject.onCompleted()
	}

	fileprivate func rerouteError<O>(_ source: O) -> Observable<O.Element> where O: ObservableConvertibleType {
		source.asObservable()
			.observe(on: MainScheduler.instance)
			.catch { [_subject] error in
				_subject.onNext(error)
				return .empty()
			}
	}
}
