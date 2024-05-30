//
//  EndpointTests.swift
//
//
//  Created by Daniel Tartaglia on 5/30/24.
//

@testable import Cause_Logic_Effect
import XCTest

final class EndpointTests: XCTestCase {
	func testSimpleRequestGeneration() {
		let url = URL(string: "http://foo.bar")!
		let body = ["query": "my operation"]
		let operation = GraphQLOperation<Void, Int>(url: url, operation: "my operation")
		let result = Endpoint.operation(operation)
		let expectedRequest = {
			var result = URLRequest(url: url)
			result.httpMethod = "POST"
			result.setValue("application/json", forHTTPHeaderField: "Content-Type")
			return result
		}()
		XCTAssertEqual(result.request, expectedRequest)
		XCTAssertEqual(result.request.httpBody, try JSONEncoder().encode(body))
	}

	func testRequestGenerationWWithVariables() {
		let url = URL(string: "http://foo.bar")!
		let body = ["variables": "hello", "query": "my operation"]
		let operation = GraphQLOperation<String, Int>(url: url, operation: "my operation")
		let result = Endpoint.operation(operation, "hello")
		let expectedRequest = {
			var result = URLRequest(url: url)
			result.httpMethod = "POST"
			result.setValue("application/json", forHTTPHeaderField: "Content-Type")
			return result
		}()
		XCTAssertEqual(result.request, expectedRequest)
		print(String(data: result.request.httpBody!, encoding: .utf8)!)
		XCTAssertEqual(try JSONSerialization.jsonObject(with: result.request.httpBody!) as! [String: String], body)
	}

	func testSuccessResponse() throws {
		let url = URL(string: "http://foo.bar")!
		let operation = GraphQLOperation<Void, Int>(url: url, operation: "my operation")
		let result = Endpoint.operation(operation)
		let data = try JSONSerialization.data(withJSONObject: ["data": 13])
		let response = try result.response(data)
		XCTAssertEqual(response, 13)
	}

	func testErrorResponse() throws {
		let url = URL(string: "http://foo.bar")!
		let operation = GraphQLOperation<Void, Int>(url: url, operation: "my operation")
		let result = Endpoint.operation(operation)
		let data = try JSONSerialization.data(withJSONObject: ["errors": [["message": "this is an error", "locations": []]]])
		do {
			_ = try result.response(data)
		} catch {
			XCTAssertEqual(error as! GraphQLErrors, GraphQLErrors(errors: [GraphQLErrors.GraphQLError(message: "this is an error", locations: [], path: nil)], data: nil))
		}
	}

	func testBadResponse() {
		let url = URL(string: "http://foo.bar")!
		let operation = GraphQLOperation<Void, Int>(url: url, operation: "my operation")
		let result = Endpoint.operation(operation)
		let data = #"{"data": { "bogus": "text"} }"#.data(using: .utf8)!
		do {
			_ = try result.response(data)
		} catch {
			XCTAssertNotNil(error as? DecodingError)
		}
	}
}
