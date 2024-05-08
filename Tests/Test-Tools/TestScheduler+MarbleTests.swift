//
//  TestScheduler+MarbleTests.swift
//
//  Created by Daniel Tartaglia on 31 October 2021.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
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

	 - parameter timeline: A string representing the marble diagrams that this observable will emit.
	 - parameter errors: A dictionary defining any substrings in the timeline that represent custom error
	 objects. Defaults to empty which means only the `#` can be used to emit an error.
	 - returns: An Observable that behaves as defined above.
	 */
	func createObservable(
		timeline: String,
		errors: [String.Element: Error] = [:]
	) -> Observable<String> {
		let events = parseTimeline(timeline, errors: errors)
		return createObservable(events)
	}

	/**
	 Creates an Observable that emits the elements in timeline up to the first stop event (or end of the
	 timeline if no stop events exist). If the Observable is subscribed to a second time, it will emit the next set
	 of events, up to the next stop event (or the end), in the timeline, or loop back to the first set of events if
	 it just handled the last set.

	 - parameter timeline: A string representing the marble diagrams that this observable will emit.
	 - parameter values: A dictionary defining any substrings in the timeline that represent a next
	 element.
	 - parameter errors: A dictionary defining any substrings in the timeline that represent custom error
	 objects. Defaults to empty which means only the `#` can be used to emit a generic error.
	 - returns: An Observable that behaves as defined above.
	 */
	func createObservable<T>(
		timeline: String,
		values: [String.Element: T],
		errors: [String.Element: Error] = [:]
	) -> Observable<T> {
		let events = parseTimeline(timeline, values: values, errors: errors)
		return createObservable(events)
	}

	/**
	 Creates an Observable that emits the recorded events in the first array of the provided jagged array. Each time
	 the Observable is subscribed to, it will emit the recorded events in the next array, or loop back to the first
	 array if it just handled the last array.

	 - parameter events: A jagged array of recorded events to play.
	 - returns: An Observable that behaves as defined above.
	 */
	func createObservable<T>(
		_ events: [[Recorded<Event<T>>]]
	) -> Observable<T> {
		var attemptCount = 0
		return Observable.deferred {
			defer { attemptCount += 1 }
			guard !events.isEmpty else { return .never() }
			return self.createColdObservable(events[attemptCount % events.count])
				.asObservable()
		}
	}

	/**
	 Enables simple construction of mock implementations from marble timelines.

	 - parameter Arg: Type of arguments of mocked method.
	 - parameter args: parameters passed into mock.
	 - parameter errors: Dictionary of errors in timeline.
	 - parameter timelineSelector: Method implementation. The returned string value represents timeline of
	 returned observable sequence. `---a---b------c----#----a--#----b`
	 - returns: Implementation of method that accepts arguments with parameter `Arg` and returns observable sequence
	 of Strings.
	 */
	func mock<Arg>(
		args: TestableObserver<Arg>,
		errors: [String.Element: Error] = [:],
		timelineSelector: @escaping (Arg) -> String
	) -> (Arg) -> Observable<String> {
		return { (parameters: Arg) -> Observable<String> in
			args.onNext(parameters)
			let timeline = timelineSelector(parameters)
			let events = parseTimeline(timeline, errors: errors)
			return self.createObservable(events)
		}
	}

	/**
	 Enables simple construction of mock implementations from marble timelines.

	 - parameter Arg: Type of arguments of mocked method.
	 - parameter Ret: Return type of mocked method. `Observable<Ret>`
	 - parameter args: parameters passed into mock.
	 - parameter values: Dictionary of values in timeline. `["a": 1, "b": 2]`
	 - parameter errors: Dictionary of errors in timeline.
	 - parameter timelineSelector: Method implementation. The returned string value represents timeline of returned
	 observable sequence. `---a---b------c----#----a--#----b`
	 - returns: Implementation of method that accepts arguments with parameter `Arg` and returns observable sequence
	 with parameter `Ret`.
	 */
	func mock<Arg, Ret>(
		args: TestableObserver<Arg>,
		values: [String.Element: Ret],
		errors: [String.Element: Error] = [:],
		timelineSelector: @escaping (Arg) -> String
	) -> (Arg) -> Observable<Ret> {
		return { (parameters: Arg) -> Observable<Ret> in
			args.onNext(parameters)
			let timeline = timelineSelector(parameters)
			return self.createObservable(timeline: timeline, values: values, errors: errors)
		}
	}
}

/**
 Creates events arrays based on an input marble diagram. Timelines can continue after a stop event which will begin a
 new array of events.

 Special characters in the timeline:
 "|": represents a completed stream.
 "#": represents a generic error in a stream.
 "-": represents the advancing of time one time-unit without emitting a value.

 Any other character represents a String value or a specialized Error type. The function will first check the
 `errors` dictionary to lookup the character, if not found an event will be created using the character.

 - parameter timeline: A string that follows the rules as defined above.
 - parameter errors: Dictionary of errors in timeline. Defaults to empty which means only the `#` can be used to emit a
 generic error.
 - parameter defaultError: The error emitted if a `#` is found in the timeline.
 - returns: An array of event arrays.
 */
public func parseTimeline(
	_ timeline: String,
	errors: [String.Element: Error] = [:],
	defaultError: Error = NSError(domain: "Test Domain", code: -1, userInfo: nil)
) -> [[Recorded<Event<String>>]] {
	parseTimeline(timeline, values: { String($0) }, errors: { errors[$0] }, defaultError: defaultError)
}

/**
 Creates events arrays based on an input marble diagram. Timelines can continue after a stop event which will begin a
 new array of events.

 Special characters in the timeline:
 "|": represents a completed stream.
 "#": represents a generic error in a stream.
 "-": represents the advancing of time one time-unit without emitting a value.

 Any other character represents a value of type `T` or a specialized Error type. The function will first check the
 `errors` dictionary to lookup the character, if not found an event will be created using the values dictionary.

 - parameter timeline: A string that follows the rules as defined above.
 - parameter values: Dictionary of values in timeline. `[a:1, b:2]`
 - parameter errors: Dictionary of errors in timeline. Defaults to empty which means only the `#` can be used to emit a
 generic error.
 - parameter defaultError: The error emitted if a `#` is found in the timeline.
 - returns: An array of event arrays.
 */
public func parseTimeline<T>(
	_ timeline: String,
	values: [String.Element: T],
	errors: [String.Element: Error] = [:],
	defaultError: Error = NSError(domain: "Test Domain", code: -1, userInfo: nil)
) -> [[Recorded<Event<T>>]] {
	parseTimeline(timeline, values: { values[$0] }, errors: { errors[$0] }, defaultError: defaultError)
}

/**
 Creates events arrays based on an input marble diagram. Timelines can continue after a stop event which will begin a
 new array of events.

 Special characters in the timeline:
 "|": represents a completed stream.
 "#": represents the default error in a stream.
 "-": represents the advancing of time one time-unit without emitting a value.

 Any other character represents a value of type T, or a specialized Error type. The function will first query the
 `errors` closure to lookup the character, if not found there it will call the `values` closure. If the `values`
 closure returns nil, it will be treated as "-".

 - parameter timeline: A string that follows the rules as defined above.
 - parameter values: A closure defining the element associated with the provided Charater or nil.
 - parameter errors: A closure defining the error associated with the provided Character, or nil.
 - parameter defaultError: The error emitted if a `#` is found in the timeline.
 - returns: An array of event arrays.
 */
public func parseTimeline<T>(
	_ timeline: String,
	values: (String.Element) -> T?,
	errors: (String.Element) -> Error? = { _ in nil },
	defaultError: Error = NSError(domain: "Test Domain", code: -1, userInfo: nil)
) -> [[Recorded<Event<T>>]] {
	parseTimelineEvents(timeline, values: { values($0).map { [$0] } ?? [] }, errors: errors, defaultError: defaultError)
}

/**
 Creates events arrays based on an input marble diagram. Timelines can continue after a stop event which will begin a
 new array of events.

 Special characters in the timeline:
 "|": represents a completed stream.
 "#": represents the default error in a stream.
 "-": represents the advancing of time one time-unit without emitting a value.

 Any other character represents one or more values of type T, or a specialized Error type. The function will first
 query the `errors` closure to lookup the character, if not found there it will call the `values` closure and create
 one event for each value returned.

 - parameter timeline: A string that follows the rules as defined above.
 - parameter values: A closure defining the element(s) associated with the provided Character. Can be empty.
 - parameter errors: A closure defining the error associated with the provided Character, or nil.
 - parameter defaultError: The error emitted if a `#` is found in the timeline.
 - returns: An array of event arrays.
 */
public func parseTimelineEvents<T>(
	_ timeline: String,
	values: (String.Element) -> [T],
	errors: (String.Element) -> Error? = { _ in nil },
	defaultError: Error = NSError(domain: "Test Domain", code: -1, userInfo: nil)
) -> [[Recorded<Event<T>>]] {
	guard !timeline.isEmpty else { return [[]] }
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
			} else {
				for each in values(char) {
					state.output[index].append(.next(state.tick, each))
				}
				state.tick += 1
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
