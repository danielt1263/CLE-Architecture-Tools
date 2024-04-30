//
//  GraphQLOperation.swift
//
//  Created by Daniel Tartaglia on 25 Feb 2024.
//  Copyright © 2024 Daniel Tartaglia. MIT License.
//

import Foundation

public struct GraphQLOperation<Input, Response> {
	let url: URL
	let operation: String

	public init(url: URL, operation: String) {
		self.url = url
		self.operation = operation
	}
}

public struct GraphQLErrors: Error, Decodable {
	public struct GraphQLError: Decodable {
		public let message: String
		public let locations: [GraphQLLocation]
		public let path: [String]?
	}

	public struct GraphQLLocation: Decodable {
		public let line: Int
		public let column: Int
	}

	public let errors: [GraphQLError]
	public let data: [String: String?]?
}

func createRequest<Body>(url: URL, body: Body, authorization: String) -> URLRequest where Body: Encodable {
	var request = URLRequest(url: url)
	request.httpMethod = "POST"
	request.setValue("application/json", forHTTPHeaderField: "Content-Type")
	if !authorization.isEmpty {
		request.setValue(authorization, forHTTPHeaderField: "Authorization")
	}
	request.httpBody = try! JSONEncoder().encode(body)
	return request
}

func parseGraphQLResponse<Response>(data: Data) throws -> Response where Response: Decodable {
	if let response = try? JSONDecoder().decode(GraphQLResponse<Response>.self, from: data).data {
		return response
	}
	if let error = try? JSONDecoder().decode(GraphQLErrors.self, from: data) {
		throw error
	}
	fatalError("Error parsing response: \(String(data: data, encoding: .utf8)!)")
}

struct GraphQLBody<Input>: Encodable where Input: Encodable {
	let variables: Input
	let query: String
}

struct GraphQLResponse<Output: Decodable>: Decodable {
	let data: Output
}
