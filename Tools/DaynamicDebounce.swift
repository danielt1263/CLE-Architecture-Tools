//
//  DynamicDebounce.swift
//
//  Created by Daniel Tartaglia on 9 May 2024.
//  Copyright © 2024 Daniel Tartaglia. MIT License.
//

import RxSwift

extension ObservableType {
	/**
	 Ignores elements from an observable sequence which are followed by another element within a relative time
	 duration, using the specified scheduler to run throttling timers. The time duration is determined by examining the
	 last element received.

	 - seealso: [debounce operator on reactivex.io](http://reactivex.io/documentation/operators/debounce.html)

	 - parameter dueTime: A closure that examines the element to determine the throttling duration.
	 - parameter scheduler: Scheduler to run the throttle timers on.
	 - returns: The throttled sequence.
	 */
	func dynamicDebounce(dueTime: @escaping (Element) -> RxTimeInterval, scheduler: SchedulerType) -> Observable<Element> {
		Observable.create { observer in
			let disposable = CompositeDisposable()
			var debouncedElement = Element?.none
			var key = CompositeDisposable.DisposeKey?.none
			let main = self.subscribe { event in
				switch event {
				case .next(let element):
					debouncedElement = element
					let sub = scheduler.scheduleRelative((), dueTime: dueTime(element), action: {
						observer.onNext(element)
						return Disposables.create()
					})
					if let key {
						disposable.remove(for: key)
					}
					key = disposable.insert(sub)
				case .error(let error):
					observer.onError(error)
				case .completed:
					if let debouncedElement {
						observer.onNext(debouncedElement)
					}
					observer.onCompleted()
				}
			}
			_ = disposable.insert(main)
			return disposable
		}
	}
}
