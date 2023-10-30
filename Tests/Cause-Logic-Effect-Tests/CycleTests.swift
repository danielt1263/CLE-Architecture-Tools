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
			reduce: { state, input in
				XCTFail()
			},
			reactions: [{ obs in
				obs.flatMap { state, input in
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
		let expected = parseEventsAndTimes(timeline: "X-Y|", values: { String($0) })
			.offsetTime(by: 200)
		let sut = cycle(
			inputs: [input],
			initialState: "X",
			reduce: { state, input in
				XCTAssertEqual(state, "X")
				XCTAssertEqual(input, "A")
				state = "Y"
			},
			reactions: [{ obs in
				obs.flatMap { state, input in
					XCTAssertEqual(state, "X")
					XCTAssertEqual(input, "A")
					return Observable<String>.empty()
				}
			}]
		)

		let result = scheduler.start { sut }

		XCTAssertEqual(result.events, expected[0])
	}

	func test2() {
		let scheduler = TestScheduler(initialClock: 0)
		let input = scheduler.createObservable(timeline: "--A---|")
		let expected = parseEventsAndTimes(timeline: "X-Y-Z-|", values: { String($0) })
			.offsetTime(by: 200)
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
			reactions: [{ obs in
				obs.flatMap { state, input in
					if input == "A" {
						XCTAssertEqual(state, "X")
						return scheduler.createObservable(timeline: "--B")
					} else {
						XCTAssertEqual(input, "B")
						XCTAssertEqual(state, "Y")
						return .empty()
					}
				}
			}]
		)

		let result = scheduler.start { sut }

		XCTAssertEqual(result.events, expected[0])
	}

	func test3() {
		let scheduler = TestScheduler(initialClock: 0)
		let input = scheduler.createObservable(timeline: "--A|")
		let expected = parseEventsAndTimes(timeline: "X-Y|", values: { String($0) })
			.offsetTime(by: 200)
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
			reactions: [{ obs in
				obs.flatMap { state, input in
					if input == "A" {
						XCTAssertEqual(state, "X")
						return scheduler.createObservable(timeline: "--B")
					} else {
						XCTAssertEqual(input, "B")
						XCTAssertEqual(state, "Y")
						return .empty()
					}
				}
			}]
		)

		let result = scheduler.start { sut }

		XCTAssertEqual(result.events, expected[0])
	}
}
