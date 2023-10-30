//
//  CycleTests.swift
//
//  Created by Daniel Tartaglia on 29 Oct 2023.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import Cause_Logic_Effect
import RxSwift
import RxTest
import Test_Tools
import XCTest

final class CycleTests: XCTestCase {
	func test() {
		let scheduler = TestScheduler(initialClock: 0)
		let input = scheduler.createObservable(timeline: "-|")
		let expected = parseEventsAndTimes(timeline: "X|", values: { String($0) })
			.offsetTime(by: 200)
		let sut = cycle(
			inputs: [input],
			initialState: "X",
			reduce: { _, _ in
				XCTFail()
			},
			reactions: [{ $0.flatMap { _, _ in
					XCTFail()
					return Observable<String>.empty()
				}
			}]
		)

		let result = scheduler.start { sut }

		XCTAssertEqual(result.events, expected[0])
	}

	func test1() {
		let scheduler = TestScheduler(initialClock: 0)
		let input = scheduler.createObservable(timeline: "--A|")
		let args = scheduler.createObserver((String, String).self)
		let expectedState = parseEventsAndTimes(timeline: "--X", values: { String($0) })
			.offsetTime(by: 200)
		let expectedInput = parseEventsAndTimes(timeline: "--A", values: { String($0) })
			.offsetTime(by: 200)
		let expectedOutput = parseEventsAndTimes(timeline: "X-Y|", values: { String($0) })
			.offsetTime(by: 200)
		let sut = cycle(
			inputs: [input],
			initialState: "X",
			reduce: { state, input in
				XCTAssertEqual(state, "X")
				XCTAssertEqual(input, "A")
				state = "Y"
			},
			reactions: [{ $0.flatMap(scheduler.mock(args: args, timelineSelector: { _ in "-|" }))}]
		)

		let result = scheduler.start { sut }

		XCTAssertEqual(args.events.map { $0.map { $0.map { $0.0 } } }, expectedState[0])
		XCTAssertEqual(args.events.map { $0.map { $0.map { $0.1 } } }, expectedInput[0])
		XCTAssertEqual(result.events, expectedOutput[0])
	}

	func test2() {
		let scheduler = TestScheduler(initialClock: 0)
		let input = scheduler.createObservable(timeline: "--A")
		let args = scheduler.createObserver((String, String).self)
		let expectedState = parseEventsAndTimes(timeline: "--X-Y", values: { String($0) })
			.offsetTime(by: 200)
		let expectedInput = parseEventsAndTimes(timeline: "--A-B", values: { String($0) })
			.offsetTime(by: 200)
		let expectedOutput = parseEventsAndTimes(timeline: "X-Y-Z", values: { String($0) })
			.offsetTime(by: 200)
		let mock = scheduler.mock(args: args, timelineSelector: { ["A": "--B|", "B": "-|"][$0.0]! })
		let sut = cycle(
			inputs: [input],
			initialState: "X",
			reduce: { state, input in
				if input == "A" {
					XCTAssertEqual(state, "X")
					state = "Y"
				} else {
					XCTAssertEqual(input, "B")
					XCTAssertEqual(state, "Y")
					state = "Z"
				}
			},
			reactions: [{ $0.flatMap(scheduler.mock(args: args, timelineSelector: { ["A": "--B|", "B": "-|"][$0.1]! }))}]
		)

		let result = scheduler.start { sut }

		XCTAssertEqual(args.events.map { $0.map { $0.map { $0.0 } } }, expectedState[0])
		XCTAssertEqual(args.events.map { $0.map { $0.map { $0.1 } } }, expectedInput[0])
		XCTAssertEqual(result.events, expectedOutput[0])
	}

	func test3() {
		let scheduler = TestScheduler(initialClock: 0)
		let input = scheduler.createObservable(timeline: "--A|")
		let args = scheduler.createObserver((String, String).self)
		let expectedState = parseEventsAndTimes(timeline: "--X", values: { String($0) })
			.offsetTime(by: 200)
		let expectedInput = parseEventsAndTimes(timeline: "--A", values: { String($0) })
			.offsetTime(by: 200)
		let expectedOutput = parseEventsAndTimes(timeline: "X-Y|", values: { String($0) })
			.offsetTime(by: 200)
		let mock = scheduler.mock(args: args, timelineSelector: { ["A": "--B|", "B": "-|"][$0.0]! })
		let sut = cycle(
			inputs: [input],
			initialState: "X",
			reduce: { state, input in
				if input == "A" {
					XCTAssertEqual(state, "X")
					state = "Y"
				} else {
					XCTAssertEqual(input, "B")
					XCTAssertEqual(state, "Y")
					state = "Z"
				}
			},
			reactions: [{ $0.flatMap(scheduler.mock(args: args, timelineSelector: { ["A": "--B", "B": "-|"][$0.1]! }))}]
		)

		let result = scheduler.start { sut }

		XCTAssertEqual(args.events.map { $0.map { $0.map { $0.0 } } }, expectedState[0])
		XCTAssertEqual(args.events.map { $0.map { $0.map { $0.1 } } }, expectedInput[0])
		XCTAssertEqual(result.events, expectedOutput[0])
	}
}

extension Recorded {
	func map<T>(_ fn: (Value) -> T) -> Recorded<T> {
		Recorded<T>(time: time, value: fn(value))
	}
}
