//
//  APITests.swift
//
//  Created by Daniel Tartaglia on 29 Oct 2023.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import Cause_Logic_Effect
import RxTest
import Test_Tools
import XCTest

final class APITests: XCTestCase {
	func testRawResponse() {
		let scheduler = TestScheduler(initialClock: 0)
		let isActive = scheduler.createObserver(Bool.self)
		let error = scheduler.createObserver(TestError.self)
		let fakeSource = scheduler.createObservable(timeline: "--E", values: ["_": Data()], errors: ["E": TestError(id: "")])
		let sut = API()
		sut.setSource { _ in fakeSource }

		var onErrorCalled = false
		_ = sut.isActive.bind(to: isActive)
		_ = sut.error.map { $0 as! TestError }.bind(to: error)
		scheduler.scheduleAt(2) {
			_ = sut.rawResponse(fakeEndpoint).subscribe(onError: { _ in
				onErrorCalled = true
			})
		}
		scheduler.start()

		XCTAssertEqual(isActive.events, parseEventsAndTimes(timeline: "F-T-F", values: { $0 == "T" })[0])
		XCTAssertEqual(error.events, [])
		XCTAssertTrue(onErrorCalled)
	}

	func testResultResponse() {
		let scheduler = TestScheduler(initialClock: 0)
		let isActive = scheduler.createObserver(Bool.self)
		let error = scheduler.createObserver(TestError.self)
		let fakeSource = scheduler.createObservable(timeline: "--E", values: ["_": Data()], errors: ["E": TestError(id: "")])
		let sut = API()
		sut.setSource { _ in fakeSource }

		var onErrorCalled = false
		_ = sut.isActive.bind(to: isActive)
		_ = sut.error.map { $0 as! TestError }.bind(to: error)
		scheduler.scheduleAt(2) {
			_ = sut.resultResponse(fakeEndpoint).subscribe(onError: { _ in
				onErrorCalled = true
			})
		}
		scheduler.start()

		XCTAssertEqual(isActive.events, parseEventsAndTimes(timeline: "F-T-F", values: { $0 == "T" })[0])
		XCTAssertEqual(error.events, [])
		XCTAssertFalse(onErrorCalled)
	}

	func testSuccessResponse() {
		let scheduler = TestScheduler(initialClock: 0)
		let isActive = scheduler.createObserver(Bool.self)
		let error = scheduler.createObserver(TestError.self)
		let errorValues = ["E": TestError(id: "E")] as [Character: TestError]
		let fakeSource = scheduler.createObservable(timeline: "--E", values: ["A": Data()], errors: errorValues)
		let expected = parseEventsAndTimes(timeline: "----E", values: errorValues)

		let sut = API()
		sut.setSource { _ in fakeSource }

		var onErrorCalled = false
		_ = sut.isActive.bind(to: isActive)
		_ = sut.error.map { $0 as! TestError }.bind(to: error)
		scheduler.scheduleAt(2) {
			_ = sut.successResponse(fakeEndpoint).subscribe(onError: { _ in
				onErrorCalled = true
			})
		}
		scheduler.start()

		XCTAssertEqual(isActive.events, parseEventsAndTimes(timeline: "F-T-F", values: { $0 == "T" })[0])
		XCTAssertEqual(error.events, expected[0])
		XCTAssertFalse(onErrorCalled)
	}

	func testBoolSuccessResponse() {
		let scheduler = TestScheduler(initialClock: 0)
		let isActive = scheduler.createObserver(Bool.self)
		let error = scheduler.createObserver(TestError.self)
		let errorValues = ["E": TestError(id: "E")] as [Character: TestError]
		let fakeSource = scheduler.createObservable(timeline: "--E", values: ["A": Data()], errors: errorValues)
		let expected = parseEventsAndTimes(timeline: "----E", values: errorValues)

		let sut = API()
		sut.setSource { _ in fakeSource }

		var onErrorCalled = false
		_ = sut.isActive.bind(to: isActive)
		_ = sut.error.map { $0 as! TestError }.bind(to: error)
		scheduler.scheduleAt(2) {
			_ = sut.successResponse(fakeVoidEndpoint).subscribe(onError: { _ in
				onErrorCalled = true
			})
		}
		scheduler.start()

		XCTAssertEqual(isActive.events, parseEventsAndTimes(timeline: "F-T-F", values: { $0 == "T" })[0])
		XCTAssertEqual(error.events, expected[0])
		XCTAssertFalse(onErrorCalled)
	}

	func testResponse() {
		let scheduler = TestScheduler(initialClock: 0)
		let isActive = scheduler.createObserver(Bool.self)
		let error = scheduler.createObserver(TestError.self)
		let errorValues = ["E": TestError(id: "E")] as [Character: TestError]
		let fakeSource = scheduler.createObservable(timeline: "--E", values: ["A": Data()], errors: errorValues)
		let expected = parseEventsAndTimes(timeline: "----E", values: errorValues)

		let sut = API()
		sut.setSource { _ in fakeSource }

		var onErrorCalled = false
		_ = sut.isActive.bind(to: isActive)
		_ = sut.error.map { $0 as! TestError }.bind(to: error)
		scheduler.scheduleAt(2) {
			_ = sut.response(fakeEndpoint).subscribe(onError: { _ in
				onErrorCalled = true
			})
		}
		scheduler.start()

		XCTAssertEqual(isActive.events, parseEventsAndTimes(timeline: "F-T-F", values: { $0 == "T" })[0])
		XCTAssertEqual(error.events, expected[0])
		XCTAssertFalse(onErrorCalled)
	}
}

struct TestError: Error, Equatable {
	let id: String
}

let fakeVoidEndpoint = Endpoint(request: URLRequest(url: URL(string: "http://foo.bar")!))
let fakeEndpoint = Endpoint(request: URLRequest(url: URL(string: "http://foo.bar")!), response: { _ in "A" })
