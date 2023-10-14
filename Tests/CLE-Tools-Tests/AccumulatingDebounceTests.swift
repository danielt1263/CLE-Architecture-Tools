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
        let values: [Character: [String]] = [
            "1": ["A", "B"],
            "2": ["C", "D"],
        ]
        let source = scheduler.createObservable(timeline: "-A-B--C-D|")
        let expected = parseEventsAndTimes(timeline:      "-----1--2|", values: { values[$0]! })
            .offsetTime(by: 200)
        let actual = scheduler.start {
            source.accumulatingDebounce(.seconds(2), scheduler: scheduler)
        }
        XCTAssertEqual(actual.events, expected[0])
    }

    func test1() {
        let scheduler = TestScheduler(initialClock: 0)
        let values: [Character: [String]] = [
            "1": ["A"],
            "2": ["B", "C"],
        ]
        let source = scheduler.createObservable(timeline: "-A--B-C---|")
        let expected = parseEventsAndTimes(timeline:      "---1----2-|", values: { values[$0]! })
            .offsetTime(by: 200)
        let actual = scheduler.start {
            source.accumulatingDebounce(.seconds(2), scheduler: scheduler)
        }
        XCTAssertEqual(actual.events, expected[0])
    }

    func test2() {
        let scheduler = TestScheduler(initialClock: 0)
        let values: [Character: [String]] = [
            "1": ["A", "B"],
        ]
        let source = scheduler.createObservable(timeline: "-A-B|")
        let expected = parseEventsAndTimes(timeline:      "---1|", values: { values[$0]! })
            .offsetTime(by: 200)
        let actual = scheduler.start {
            source.accumulatingDebounce(.seconds(2), scheduler: scheduler)
        }
        XCTAssertEqual(actual.events, expected[0])
    }
}
