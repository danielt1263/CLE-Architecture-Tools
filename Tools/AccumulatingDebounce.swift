//
//  AccumulatingDebounce.swift
//
//  Created by Daniel Tartaglia on 10 Mar 2023.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

extension ObservableType {
	/**
	 Accumulates elements from an observable sequence where are followed by another element within a specified relative time
	 duration, using the specified scheduler to run throttling timers.

	 - Parameters:
	 - dueTime: Throttling duration for each element.
	 - scheduler:  Scheduler to run the throttle timers on.
	 - Returns: The throttled sequence.
	 */
	func accumulatingDebounce(_ dueTime: RxTimeInterval, scheduler: SchedulerType) -> Observable<[Element]> {
		.create { observer in
			var state = [Element]()
			var nextEmit = Disposable?.none
			let lock = NSRecursiveLock()
			let disposable = self.subscribe { event in
				lock.lock(); defer { lock.unlock() }
				switch event {
				case .next(let element):
					state.append(element)
					nextEmit?.dispose()
					nextEmit = scheduler.scheduleRelative((), dueTime: dueTime) {
						lock.lock(); defer { lock.unlock() }
						observer.onNext(state)
						state = []
						return Disposables.create()
					}
				case .error(let error):
					observer.onError(error)
				case .completed:
					if !state.isEmpty { observer.onNext(state) }
					observer.onCompleted()
				}
			}
			return Disposables.create(disposable, nextEmit ?? Disposables.create())
		}
	}
}
