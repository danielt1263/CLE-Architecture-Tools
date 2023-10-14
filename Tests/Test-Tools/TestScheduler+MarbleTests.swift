//
//  TestScheduler+MarbleTests.swift
//
//  Created by Daniel Tartaglia on 31 October 2021.
//  Copyright © 2022 Daniel Tartaglia. All rights reserved.
//

import Foundation
import RxSwift
import RxTest

public extension TestScheduler {
	/**
	 Creates an Observable that emits the elements in timeline up to the first stop event (or end of the
	 timeline if no stop events exist). If the Observable is subscribed to a second time, it will emit the next set
	 of events, up to the next stop event (or the end), in the timeline, or loop back to the first set of events if
	 it just handled the last set.
	 - Parameter timeline: A string representing the marble diagrams that this observable will emit.
	 - Parameter errors: A dictionary defining any substrings in the timeline that represent custom error
	 objects. Defaults to empty which means only the `#` can be used to emit an error.
	 - Parameter resolution: A closure telling the function what resolution to use when timing
	 events. Defaults to one second per character.
	 - Returns: An Observable that behaves as defined above.
	 */
	func createObservable(
		timeline: String,
		errors: [String.Element: Error] = [:],
		resolution: @escaping (TestTime) -> RxTimeInterval = { .seconds($0) }
	) -> Observable<String> {
		let events = parseEventsAndTimes(timeline: timeline, values: { String($0) }, errors: { errors[$0] })
		return createObservable(events, resolution: resolution)
	}

	/**
	 Creates an Observable that emits the elements in timeline up to the first stop event (or end of the
	 timeline if no stop events exist). If the Observable is subscribed to a second time, it will emit the next set
	 of events, up to the next stop event (or the end), in the timeline, or loop back to the first set of events if
	 it just handled the last set.
	 - Parameter timeline: A string representing the marble diagrams that this observable will emit.
	 - Parameter values: A dictionary defining any substrings in the timeline that represent a next
	 element.
	 - Parameter errors: A dictionary defining any substrings in the timeline that represent custom error
	 objects. Defaults to empty which means only the `#` can be used to emit a generic error.
	 - Parameter resolution: A closure telling the function what resolution to use when timing
	 events. Defaults to one second per character.
	 - Returns: An Observable that behaves as defined above.
	 */
	func createObservable<T>(
		timeline: String,
		values: [String.Element: T],
		errors: [String.Element: Error] = [:],
		resolution: @escaping (TestTime) -> RxTimeInterval = { .seconds($0) }
	) -> Observable<T> {
		let events = parseEventsAndTimes(timeline: timeline, values: { values[$0] }, errors: { errors[$0] })
		return createObservable(events, resolution: resolution)
	}

	/**
	 Creates an Observable that emits the recorded events in the provided array. If the Observable is
	 subscribed to a second time, it will replay the array of events.
	 - Parameter events: An array of recorded events to play.
	 - Parameter resolution: A closure telling the function what resolution to use when timing
	 events. Defaults to one second times the `Recorded` event's test time.
	 - Returns: An Observable that behaves as defined above.
	 */
	func createObservable<T>(
		_ events: [Recorded<Event<T>>],
		resolution: @escaping (TestTime) -> RxTimeInterval = { .seconds($0) }
	) -> Observable<T> {
		createObservable([events], resolution: resolution)
	}

	/**
	 Creates an Observable that emits the recorded events in the first array of the provided two dimensional
	 array. Each time the Observable is subscribed to, it will emit the recorded events in the next array, or
	 loop back to the first array if it just handled the last array.
	 - Parameter events: A two-dimensional array of recorded events to play.
	 - Parameter resolution: A closure telling the function what resolution to use when timing
	 events. Defaults to one second times the `Recorded` event's test time.
	 - Returns: An Observable that behaves as defined above.
	 */
	func createObservable<T>(
		_ events: [[Recorded<Event<T>>]],
		resolution: @escaping (TestTime) -> RxTimeInterval = { .seconds($0) }
	) -> Observable<T> {
		var attemptCount = 0
		return Observable.create { observer in
			let scheduledEvents = events[attemptCount % events.count].map { event in
				return self.scheduleRelative((), dueTime: resolution(event.time)) {
					observer.on(event.value)
					return  Disposables.create()
				}
			}
			attemptCount += 1
			return Disposables.create(scheduledEvents)
		}
	}

	/**
	 Enables simple construction of mock implementations from marble timelines.

	 - parameter Arg: Type of arguments of mocked method.
	 - parameter Ret: Return type of mocked method. `Observable<Ret>`

	 - parameter args: parameters passed into mock.
	 - parameter values: Dictionary of values in timeline. `["a": 1, "b": 2]`
	 - parameter errors: Dictionary of errors in timeline.
	 - parameter timelineSelector: Method implementation. The returned string value represents timeline of
	 returned observable sequence. `---a---b------c----#----a--#----b`

	 - returns: Implementation of method that accepts arguments with parameter `Arg` and returns observable sequence
	 with parameter `Ret`.
	 */
	func mock<Arg, Ret>(
		args: TestableObserver<Arg>,
		values: [String.Element: Ret],
		errors: [String.Element: Error] = [:],
		timelineSelector: @escaping (Arg) -> String,
		resolution: @escaping (TestTime) -> RxTimeInterval = { .seconds($0) }
	) -> (Arg) -> Observable<Ret> {
		return { (parameters: Arg) -> Observable<Ret> in
			args.onNext(parameters)
			let timeline = timelineSelector(parameters)
			return self.createObservable(timeline: timeline, values: values, errors: errors, resolution: resolution)
		}
	}

	func mock<Arg>(
		args: TestableObserver<Arg>,
		errors: [String.Element: Error] = [:],
		timelineSelector: @escaping (Arg) -> String,
		resolution: @escaping (TestTime) -> RxTimeInterval = { .seconds($0) }
	) -> (Arg) -> Observable<String> {
		return { (parameters: Arg) -> Observable<String> in
			args.onNext(parameters)
			let timeline = timelineSelector(parameters)
			let events = parseEventsAndTimes(timeline: timeline, values: { String($0) }, errors: { errors[$0] })
			return self.createObservable(events, resolution: resolution)
		}
	}
}

/**
 Creates events arrays based on an input marble diagram. Timelines can continue after a stop event which
 will begin a new array of events.

 Special characters in the timeline:
 "|": represents a completed stream.
 "#": represents a generic error in a stream.
 "-": represents the advancing of time one time-unit without emitting a value.

 Any other character represents a value of type T, or a specialized Error type. The function will first query the
 `errors` closure to lookup the character, if not found there it will call the `values` closure. If neither
 closure returns an object for the substring, then an error will be asserted.

 - Parameter timeline: A string that follows the rules as defined above.
 - Parameter values: A closure defining any substrings in the timeline that represent a next element.
 - Parameter errors: A closure defining any substrings in the timeline that represent custom error
 objects. Defaults to none which means only the `#` can be used to emit a generic error.
 - Returns: An array of event arrays.
 */
public func parseEventsAndTimes<T>(
	timeline: String,
	values: (String.Element) -> T?,
	errors: (String.Element) -> Error? = { _ in nil },
	defaultError: Error = NSError(domain: "Test Domain", code: -1, userInfo: nil)
) -> [[Recorded<Event<T>>]] {
	return timeline.reduce(into: EventsAndTimeState<T>()) { state, char in
		if state.tick == 0 {
			state.output.append([])
		}
		let index = state.output.count - 1
		switch char {
		case "|":
			state.output[index].append(.completed(max(state.tick - 1, 0)))
			state.tick = 0
		case "#":
			state.output[index].append(.error(state.tick, defaultError))
			state.tick = 0
		case "-":
			state.tick += 1
		default:
			if let error = errors(char) {
				state.output[index].append(.error(state.tick, error))
				state.tick = 0
			} else if let element = values(char) {
				state.output[index].append(.next(state.tick, element))
				state.tick += 1
			} else {
				fatalError("unable to convert value into event: \(char)")
			}
		}
	}
	.output
}

public extension Array {
	func offsetTime<T>(by time: Int) -> [[Recorded<Event<T>>]] where Element == [Recorded<Event<T>>] {
		map { $0.map { Recorded(time: $0.time + time, value: $0.value) } }
	}
}

private struct EventsAndTimeState<T> {
	var output: [[Recorded<Event<T>>]] = []
	var tick: Int = 0
}
