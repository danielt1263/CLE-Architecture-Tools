//
//  ReactionTests.swift
//  
//  Created by Daniel Tartaglia on 30 Oct 2023.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import Cause_Logic_Effect
import RxSwift
import RxTest
import Test_Tools
import XCTest

final class ReactionTests: XCTestCase {
	func testStoppable() {
		let scheduler = TestScheduler(initialClock: 0)
		let source = scheduler.createObservable(timeline: "-A-B-X-C", values: [
			"A": (State(), Character("A")),
			"B": (State(), Character("B")),
			"C": (State(), Character("C")),
			"X": (State(), Character("X")),
		])
		let args = scheduler.createObserver(String.self)
		let mock = scheduler.mock(args: args, timelineSelector: { ["A": "---1|", "B": "---2|", "C": "--3|"][$0]! })
		let sut = stoppable(Payload(action: activityAction(state:input:), result: { $1.first! }), effect: mock)
		let result = scheduler.start {
			sut(source)
		}
		XCTAssertEqual(args.events, parseTimeline("-A-B---C").offsetTime(by: 200)[0])
		XCTAssertEqual(result.events, parseTimeline("---------3", values: { $0 }).offsetTime(by: 200)[0])
	}

	func testMargable() {
		let scheduler = TestScheduler(initialClock: 0)
		let source = scheduler.createObservable(timeline: "-A-B-X-C", values: [
			"A": (State(), Character("A")),
			"B": (State(), Character("B")),
			"C": (State(), Character("C")),
			"X": (State(), Character("X")),
		])
		let args = scheduler.createObserver(String.self)
		let mock = scheduler.mock(args: args, timelineSelector: { ["A": "---1|", "B": "---2|", "C": "--3|"][$0]! })
		let sut = mergable(Payload(action: action(state:input:), result: { $1.first! }), effect: mock)
		let result = scheduler.start {
			sut(source)
		}
		XCTAssertEqual(args.events, parseTimeline("-A-B---C").offsetTime(by: 200)[0])
		XCTAssertEqual(result.events, parseTimeline("----1-2--3", values: { $0 }).offsetTime(by: 200)[0])
	}

	func testIgnorable() {
		let scheduler = TestScheduler(initialClock: 0)
		let source = scheduler.createObservable(timeline: "-A-B-X-C", values: [
			"A": (State(), Character("A")),
			"B": (State(), Character("B")),
			"C": (State(), Character("C")),
			"X": (State(), Character("X")),
		])
		let args = scheduler.createObserver(String.self)
		let mock = scheduler.mock(args: args, timelineSelector: { ["A": "---1|", "B": "---2|", "C": "--3|"][$0]! })
		let sut = ignorable(Payload(action: action(state:input:), result: { $1.first! }), effect: mock)
		let result = scheduler.start {
			sut(source)
		}
		XCTAssertEqual(args.events, parseTimeline("-A-----C").offsetTime(by: 200)[0])
		XCTAssertEqual(result.events, parseTimeline("----1----3", values: { $0 }).offsetTime(by: 200)[0])
	}

	func testStackable() {
		let scheduler = TestScheduler(initialClock: 0)
		let source = scheduler.createObservable(timeline: "-A-B-X-C", values: [
			"A": (State(), Character("A")),
			"B": (State(), Character("B")),
			"C": (State(), Character("C")),
			"X": (State(), Character("X")),
		])
		let args = scheduler.createObserver(String.self)
		let mock = scheduler.mock(args: args, timelineSelector: { ["A": "---1|", "B": "---2|", "C": "--3|"][$0]! })
		let sut = stackable(Payload(action: action(state:input:), result: { $1.first! }), effect: mock)
		let result = scheduler.start {
			sut(source)
		}
		XCTAssertEqual(args.events, parseTimeline("-A-B---C").offsetTime(by: 200)[0])
		XCTAssertEqual(result.events, parseTimeline("----1--2-3", values: { $0 }).offsetTime(by: 200)[0])
	}
}

struct State { }

func activityAction(state: State, input: Character) -> Activity<String>? {
	switch input {
	case "X":
		return .stop
	case "Y":
		return nil
	default:
		return .restart(String(input))
	}
}

func action(state: State, input: Character) -> String? {
	input == "X" ? nil : String(input)
}
