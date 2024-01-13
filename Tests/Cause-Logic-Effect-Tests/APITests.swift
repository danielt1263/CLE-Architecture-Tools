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
	let scheduler = TestScheduler(initialClock: 0)
	lazy var isActive: TestableObserver<Bool> = scheduler.createObserver(Bool.self)
	lazy var error = scheduler.createObserver(TestError.self)
	lazy var fakeSource = scheduler.createObservable(
		timeline: "--E",
		values: ["_": Data()],
		errors: ["E": TestError(id: "E")]
	)
	let expected = parseTimeline("----E", values: ["E": TestError(id: "E")])
	var onErrorCalled = false

	func testRawResponse() {
		let sut = API()
		sut.setSource { _ in self.fakeSource }

		_ = sut.isActive.bind(to: isActive)
		_ = sut.error.map { $0 as! TestError }.bind(to: error)
		scheduler.scheduleAt(2) {
			_ = sut.rawResponse(fakeEndpoint).subscribe(onError: { _ in
				self.onErrorCalled = true
			})
		}
		scheduler.start()

		XCTAssertEqual(isActive.events, parseTimeline("F-T-F", values: { $0 == "T" })[0])
		XCTAssertEqual(error.events, [])
		XCTAssertTrue(onErrorCalled)
	}

	func testResultResponse() {
		let sut = API()
		sut.setSource { _ in self.fakeSource }

		var result: Result<Int, TestError>?
		_ = sut.isActive.bind(to: isActive)
		_ = sut.error.map { $0 as! TestError }.bind(to: error)
		scheduler.scheduleAt(2) {
			_ = sut.resultResponse(fakeEndpoint).subscribe(
				onNext: { result = $0.mapError { $0 as! TestError } },
				onError: { _ in
					self.onErrorCalled = true
				})
		}
		scheduler.start()

		XCTAssertEqual(isActive.events, parseTimeline("F-T-F", values: { $0 == "T" })[0])
		XCTAssertEqual(result, .failure(TestError(id: "E")))
		XCTAssertEqual(error.events, [])
		XCTAssertFalse(onErrorCalled)
	}

	func testSuccessResponse() {
		let fakeSource = scheduler.createObservable(timeline: "--E", values: ["A": Data()], errors: ["E": TestError(id: "E")])
		let sut = API()
		sut.setSource { _ in self.fakeSource }

		_ = sut.isActive.bind(to: isActive)
		_ = sut.error.map { $0 as! TestError }.bind(to: error)
		scheduler.scheduleAt(2) {
			_ = sut.successResponse(fakeEndpoint).subscribe(onError: { _ in
				self.onErrorCalled = true
			})
		}
		scheduler.start()

		XCTAssertEqual(isActive.events, parseTimeline("F-T-F", values: { $0 == "T" })[0])
		XCTAssertEqual(error.events, expected[0])
		XCTAssertFalse(onErrorCalled)
	}

	func testBoolSuccessResponse() {
		let sut = API()
		sut.setSource { _ in self.fakeSource }

		let fakeEndpoint = Endpoint(request: URLRequest(url: URL(string: "http://foo.bar")!))

		_ = sut.isActive.bind(to: isActive)
		_ = sut.error.map { $0 as! TestError }.bind(to: error)
		scheduler.scheduleAt(2) {
			_ = sut.successResponse(fakeEndpoint).subscribe(onError: { _ in
				self.onErrorCalled = true
			})
		}
		scheduler.start()

		XCTAssertEqual(isActive.events, parseTimeline("F-T-F", values: { $0 == "T" })[0])
		XCTAssertEqual(error.events, expected[0])
		XCTAssertFalse(onErrorCalled)
	}

	func testResponse() {
		let sut = API()
		sut.setSource { _ in self.fakeSource }

		_ = sut.isActive.bind(to: isActive)
		_ = sut.error.map { $0 as! TestError }.bind(to: error)
		scheduler.scheduleAt(2) {
			_ = sut.response(fakeEndpoint).subscribe(onError: { _ in
				self.onErrorCalled = true
			})
		}
		scheduler.start()

		XCTAssertEqual(isActive.events, parseTimeline("F-T-F", values: { $0 == "T" })[0])
		XCTAssertEqual(error.events, expected[0])
		XCTAssertFalse(onErrorCalled)
	}
}

struct TestError: Error, Equatable {
	let id: String
}

let fakeEndpoint = Endpoint(request: URLRequest(url: URL(string: "http://foo.bar")!), response: { _ in 5 })
