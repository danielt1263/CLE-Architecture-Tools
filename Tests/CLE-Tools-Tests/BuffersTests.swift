//
//  BuffersTests.swift
//
//  Created by Daniel Tartaglia on 14 Oct 2023.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

@testable import CLE_Tools
import RxTest
import Test_Tools
import XCTest

final class BuffersTests: XCTestCase {
	func test() {
		let scheduler = TestScheduler(initialClock: 0)
		let source = scheduler.createObservable(timeline: "-A-B-C-D-E-F--|")
		let expected = parseTimeline("---1---2---3-4|", values: [
			"1": ["A", "B"],
			"2": ["C", "D"],
			"3": ["E", "F"],
			"4": [],
		])
			.offsetTime(by: 200)
		let actual = scheduler.start {
			source.buffer(count: 2, skip: 2)
		}
		XCTAssertEqual(actual.events, expected[0])
	}

	func test1() {
		let scheduler = TestScheduler(initialClock: 0)
		let source = scheduler.createObservable(timeline: "-A-B-C-D-E-F--|")
		let expected = parseTimeline("---1-----2---3|", values: [
			"1": ["A", "B"],
			"2": ["D", "E"],
			"3": [],
		])
			.offsetTime(by: 200)
		let actual = scheduler.start {
			source.buffer(count: 2, skip: 3)
		}
		XCTAssertEqual(actual.events, expected[0])
	}

	func test2() {
		let scheduler = TestScheduler(initialClock: 0)
		let source = scheduler.createObservable(timeline: "-A-B-C-D-E-F--|")
		let expected = parseTimeline("-----1---2---3|", values: [
			"1": ["A", "B", "C"],
			"2": ["C", "D", "E"],
			"3": ["E", "F"],
		])
			.offsetTime(by: 200)
		let actual = scheduler.start {
			source.buffer(count: 3, skip: 2)
		}
		XCTAssertEqual(actual.events, expected[0])
	}

	func test3() {
		let scheduler = TestScheduler(initialClock: 0)
		let source = scheduler.createObservable(timeline: "-A-B-C-D-E-F--|")
		let expected = parseTimeline("----1---2---34|", values: [
			"1": ["A", "B"],
			"2": ["C", "D"],
			"3": ["E", "F"],
			"4": [],
		])
			.offsetTime(by: 200)
		let actual = scheduler.start {
			source.buffer(timeSpan: .seconds(4), timeShift: .seconds(4), scheduler: scheduler)
		}
		XCTAssertEqual(actual.events, expected[0])
	}

	func test4() {
		let scheduler = TestScheduler(initialClock: 0)
		let source = scheduler.createObservable(timeline: "-A-B-C-D-E-F--|")
		let expected = parseTimeline("----1-----2--3|", values: [
			"1": ["A", "B"],
			"2": ["D", "E"],
			"3": [],
		])
			.offsetTime(by: 200)
		let actual = scheduler.start {
			source.buffer(timeSpan: .seconds(4), timeShift: .seconds(6), scheduler: scheduler)
		}
		XCTAssertEqual(actual.events, expected[0])
	}

	func test5() {
		let scheduler = TestScheduler(initialClock: 0)
		let source = scheduler.createObservable(timeline: "-A-B-C-D-E-F--|")
		let expected = parseTimeline("------1---2--3|", values: [
			"1": ["A", "B", "C"],
			"2": ["C", "D", "E"],
			"3": ["E", "F"],
		])
			.offsetTime(by: 200)
		let actual = scheduler.start {
			source.buffer(timeSpan: .seconds(6), timeShift: .seconds(4), scheduler: scheduler)
		}
		XCTAssertEqual(actual.events, expected[0])
	}

	func test6() {
		let scheduler = TestScheduler(initialClock: 0)
		let source = scheduler.createObservable(timeline: "-A-B-C-D-A-B-|", values: [
			"A": "Apple",
			"B": "Ball",
			"C": "Cat",
			"D": "Dog",
		])
		let result = scheduler.start {
			source.buffer(shouldInclude: { $0.map(\.count).reduce(0, +) + $1.count <= 10 })
		}
		let expected = parseTimeline("-----A---B--C|", values: [
			"A": ["Apple", "Ball"],
			"B": ["Cat", "Dog"],
			"C": ["Apple", "Ball"],
		]).offsetTime(by: 200)
		XCTAssertEqual(result.events, expected[0])
	}
}
