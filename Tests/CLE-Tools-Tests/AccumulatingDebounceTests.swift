//
//  ThrottleDebounceLatestTests.swift
//
//  Created by Daniel Tartaglia on 14 Oct 2023.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import RxTest
import Test_Tools
import XCTest
@testable import CLE_Tools

final class AccumulatingDebounceTests: XCTestCase {
	func test() {
		let scheduler = TestScheduler(initialClock: 0)
		let source = scheduler.createObservable(timeline: "-A-B--C-D|")
		let expected = parseTimeline("-----1--2|", values: ["1": ["A", "B"], "2": ["C", "D"]])
			.offsetTime(by: 200)
		let actual = scheduler.start {
			source.accumulatingDebounce(.seconds(2), scheduler: scheduler)
		}
		XCTAssertEqual(actual.events, expected[0])
	}

	func test1() {
		let scheduler = TestScheduler(initialClock: 0)
		let source = scheduler.createObservable(timeline: "-A--B-C---|")
		let expected = parseTimeline("---1----2-|", values: ["1": ["A"], "2": ["B", "C"]])
			.offsetTime(by: 200)
		let actual = scheduler.start {
			source.accumulatingDebounce(.seconds(2), scheduler: scheduler)
		}
		XCTAssertEqual(actual.events, expected[0])
	}

	func test2() {
		let scheduler = TestScheduler(initialClock: 0)
		let source = scheduler.createObservable(timeline: "-A-B|")
		let expected = parseTimeline("---1|", values: ["1": ["A", "B"]])
			.offsetTime(by: 200)
		let actual = scheduler.start {
			source.accumulatingDebounce(.seconds(2), scheduler: scheduler)
		}
		XCTAssertEqual(actual.events, expected[0])
	}
}
