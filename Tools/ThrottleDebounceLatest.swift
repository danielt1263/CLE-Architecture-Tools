//
//  ThrottleDebounceLatest.swift
//
//  Created by Daniel Tartaglia on 14 Oct 2023.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

extension ObservableType {
	/**
	 returns an Observable that emits the first item emitted by the source Observable then ignores elements from the
	 source which are followed by another element within a specified relative time duration, using the specified
	 scheduler to run throttling timers.

	 - parameter dueTime: Throttling duration for each element.
	 - parameter scheduler: Scheduler to run the throttle timers on.
	 - returns: The throttled sequence.
	 */
	func throttleDebounceLatest(dueTime: RxTimeInterval, scheduler: SchedulerType) -> Observable<Element> {
		Observable.create { observer in
			var fireTime: RxTime?
			var nextEmit = Disposable?.none
			let lock = NSRecursiveLock()
			func delay(event: Event<Self.Element>) -> Disposable {
				scheduler.scheduleRelative((), dueTime: dueTime) {
					lock.lock(); defer { lock.unlock() }
					observer.on(event)
					nextEmit = nil
					return Disposables.create()
				}
			}
			return self.subscribe { event in
				lock.lock(); defer { lock.unlock() }
				switch event {
				case .next:
					if fireTime == nil || dueTime.asTimeInterval < scheduler.now.timeIntervalSince(fireTime!) {
						observer.on(event)
					} else {
						nextEmit?.dispose()
						nextEmit = delay(event: event)
					}
					fireTime = scheduler.now
				case .error:
					nextEmit?.dispose()
					observer.on(event)
				case .completed:
					if nextEmit == nil {
						observer.on(event)
					} else {
						nextEmit = delay(event: event)
					}
				}
			}
		}
	}
}

private extension DispatchTimeInterval {
	var asTimeInterval: TimeInterval {
		switch self {
		case .nanoseconds(let val): return Double(val) / 1_000_000_000.0
		case .microseconds(let val): return Double(val) / 1_000_000.0
		case .milliseconds(let val): return Double(val) / 1_000.0
		case .seconds(let val): return Double(val)
		case .never: return Double.infinity
		@unknown default: fatalError()
		}
	}
}
