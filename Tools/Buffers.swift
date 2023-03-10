//
//  Buffers.swift
//
//  Created by Daniel Tartaglia on 04 Apr, 2019
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import RxSwift

extension ObservableType {

	/**
	 Projects elements from an observable sequence into a buffer that's sent out when its full and then every `skip` elements.

	 - seealso: [overlapping buffers in Introduction to Rx](http://introtorx.com/Content/v1.0.10621.0/13_TimeShiftedSequences.html#OverlappingBuffersByCount)

	 - parameter count: Size of the array of elements that will be produced in each event.
	 - parameter skip: Number of elements that must emit from the source before the buffer emits.
	 - returns: An observable sequence of buffers.
	 */
	func buffer(count: Int, skip: Int) -> Observable<[Element]> {
		precondition(skip > 0, "The `skip` parameter cannot be less than or equal to zero. If you want to use a value of zero (i.e. each buffer contains all values), then consider using the `scan` method instead with an Array<T> as the accumulator.")

		return self
			.materialize()
			.scan(into: (buf: [Element](), step: count, trigger: false)) { prev, event in
				switch event {
				case let .next(value):
					let newStep = prev.step - 1
					prev.buf.append(value)
					if prev.buf.count > count {
						prev.buf.removeFirst()
					}
					prev.step = newStep == 0 ? skip : newStep
					prev.trigger = newStep == 0
				case .completed:
					prev.buf = Array(prev.buf.suffix(count - prev.step))
					prev.step = 0
					prev.trigger = !prev.buf.isEmpty
				case let .error(error):
					throw error
				}
			}
			.filter { $0.trigger }
			.map { $0.buf }
	}
}

extension ObservableType {

	/**
	 Projects elements from an observable sequence into a buffer that's sent out after `timeSpan` and then every `timeShift` seconds.

	 - seealso: [overlapping buffers in Introduction to Rx](http://introtorx.com/Content/v1.0.10621.0/13_TimeShiftedSequences.html#OverlappingBuffersByTime)

	 - parameter timeSpan: The amount of time the operator will spend gathering events.
	 - parameter timeShift: The amount of time that must pass before the buffer emits.
	 - parameter scheduler: Scheduler to run timers on.
	 - returns: An observable sequence of buffers.
	 */
	func buffer(timeSpan: RxTimeInterval, timeShift: RxTimeInterval, scheduler: SchedulerType) -> Observable<[Element]> {
		precondition(timeShift.asTimeInterval > 0, "The `timeShift` parameter cannot be less than or equal to zero. If you want to use a value of zero (i.e. each buffer contains all values), then consider using the `scan` method instead with an Array<T> as the accumulator.")
		return Observable.create { observer in
			var buf: [Date: Element] = [:]
			var lastEmit: Date?
			let lock = NSRecursiveLock()
			let bufferDispoable = self.subscribe { event in
				lock.lock(); defer { lock.unlock() }
				let now = scheduler.now
				switch event {
				case let .next(element):
					buf[now] = element
				case .completed:
					if let lastEmit = lastEmit {
						let span = now.timeIntervalSince(lastEmit) + timeSpan.asTimeInterval - timeShift.asTimeInterval
						observer.onNext(buf
							.filter { $0.key > now.addingTimeInterval(-span) }
							.sorted(by: { $0.key <= $1.key })
							.map { $0.value })
					}
					else {
						observer.onNext(buf
							.sorted(by: { $0.key <= $1.key })
							.map { $0.value })
					}
					observer.onCompleted()
				case let .error(error):
					observer.onError(error)
				}
			}
			let schedulerDisposable = scheduler.schedulePeriodic((), startAfter: timeSpan, period: timeShift, action: { state in
				lock.lock(); defer { lock.unlock() }
				let now = scheduler.now
				buf = buf.filter { $0.key > now.addingTimeInterval(-timeSpan.asTimeInterval) }
				observer.onNext(buf.sorted(by: { $0.key <= $1.key }).map { $0.value })
				lastEmit = now
			})
			return Disposables.create([schedulerDisposable, bufferDispoable])
		}
	}}

extension ObservableType {

	/**
	 Projects elements from an observable sequence into a buffer that's sent out when the boundary sequence fires. Then it emits the elements as an array and begins collecting again.

	 - parameter boundary: Triggering event sequence.
	 - returns: Array of elements observable sequence.
	 */
	func buffer<O>(boundary: O) -> Observable<[Element]> where O: ObservableConvertibleType {
		return Observable.merge(self.materialize().map(BufferAction.element), boundary.asObservable().map { _ in BufferAction.trigger })
			.scan((buf: [Element](), trigger: ([Element]?).none)) { prev, next in
				switch next {
				case let .element(event):
					switch event {
					case .next(let e):
						return (buf: prev.buf + [e], trigger: nil)
					case .error(let error):
						throw error
					case .completed:
						return (buf: [], trigger: prev.buf)
					}
				case .trigger:
					return (buf: [], trigger: prev.buf)
				}
			}
			.filter { $0.trigger != nil }
			.map { $0.trigger! }
			.take(until: self.takeLast(0))
	}
}

private enum BufferAction<T> {
	case element(Event<T>)
	case trigger
}

private extension DispatchTimeInterval {
	var asTimeInterval: TimeInterval {
		switch self {
		case .nanoseconds(let val): return Double(val) / 1_000_000_000.0
		case .microseconds(let val): return Double(val) / 1_000_000.0
		case .milliseconds(let val): return Double(val) / 1_000.0
		case .seconds(let val): return Double(val)
		case .never: return Double.infinity
		default: fatalError()
		}
	}
}
