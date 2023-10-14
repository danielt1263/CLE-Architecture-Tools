//
//  StallUnless.swift
//
//  Created by Daniel Tartaglia on 1 Oct 2018.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import RxSwift

extension ObservableType {

	/**
	 Emits values immediately if the boundary sequence last emitted true, otherwise collects elements from the source
	 sequence until the boundary sequence emits true then emits the collected elements.

	 - parameter boundary: Triggering event sequence.
	 - parameter initial: The initial value of the boundary
	 - returns: An Observable sequence.
	 */
	func stall<O>(unless boundary: O, initial: Bool) -> Observable<Element> where O: ObservableType, O.Element == Bool {
		Observable.merge(
			map(Action.value),
			boundary
				.startWith(initial)
				.distinctUntilChanged()
				.materialize()
				.map(Action.trigger)
				.take(until: takeLast(1))
		)
		.scan((buffer: [Element](), trigger: initial, out: [Element]()), accumulator: { current, new in
			switch new {
			case .value(let value):
				return current.trigger ? (buffer: [], trigger: current.trigger, out: [value]) : (buffer: current.buffer + [value], trigger: current.trigger, out: [])
			case .trigger(.next(let trigger)):
				return trigger ? (buffer: [], trigger: trigger, out: current.buffer) : (buffer: current.buffer, trigger: trigger, out: [])
			case .trigger(.completed):
				return (buffer: [], trigger: true, out: current.buffer)
			case .trigger(.error(let error)):
				throw error
			}
		})
		.flatMap { $0.out.isEmpty ? Observable.empty() : Observable.from($0.out) }
	}
}

private enum Action<E> { case value(E); case trigger(Event<Bool>) }
