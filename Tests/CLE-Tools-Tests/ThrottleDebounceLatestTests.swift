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

class ThrottleDebounceLatestTests: XCTestCase {
	func test() {
		let scheduler = TestScheduler(initialClock: 0)
		let source = scheduler.createObservable(timeline: "-A-B-C-D-----E-F-G-H-I-J-K-L-------M----------N---------")
		let expected = parseEventsAndTimes(timeline:      "-A-------D---E---------------L-----M----------N---------", values: { String($0) })
			.offsetTime(by: 200)
		let actual = scheduler.start {
			source.throttleDebounceLatest(dueTime: .seconds(2), scheduler: scheduler)
		}
		XCTAssertEqual(actual.events, expected[0])
	}

	func test1() {
		let scheduler = TestScheduler(initialClock: 0)
		let source = scheduler.createObservable(timeline: "-A-B-C-D|")
		let expected = parseEventsAndTimes(timeline:      "-A-----D|", values: { String($0) })
			.offsetTime(by: 200)
		let actual = scheduler.start {
			source.throttleDebounceLatest(dueTime: .seconds(2), scheduler: scheduler)
		}
		XCTAssertEqual(actual.events, expected[0])
	}

	func test2() {
		let scheduler = TestScheduler(initialClock: 0)
		let source = scheduler.createObservable(timeline: "-A|")
		let expected = parseEventsAndTimes(timeline:      "-A|", values: { String($0) })
			.offsetTime(by: 200)
		let actual = scheduler.start {
			source.throttleDebounceLatest(dueTime: .seconds(2), scheduler: scheduler)
		}
		XCTAssertEqual(actual.events, expected[0])
	}

	func test3() {
		let scheduler = TestScheduler(initialClock: 0)
		let source = scheduler.createObservable(timeline: "-A-B-C-D-----|")
		let expected = parseEventsAndTimes(timeline:      "-A-------D---|", values: { String($0) })
			.offsetTime(by: 200)
		let actual = scheduler.start {
			source.throttleDebounceLatest(dueTime: .seconds(2), scheduler: scheduler)
		}
		XCTAssertEqual(actual.events, expected[0])
	}
}
