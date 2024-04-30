//
//  Endpoint.swift
//
//  Created by Daniel Tartaglia on 24 Feb 2024.
//  Copyright © 2024 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

/**
 An abstraction defining a server endpoint.
 */
public struct Endpoint<Response> {
	public let request: URLRequest
	public let response: (Data) throws -> Response

	public init(request: URLRequest, response: @escaping (Data) throws -> Response) {
		self.request = request
		self.response = response
	}
}

public extension Endpoint where Response: Decodable {
	/**
	 Create an endpoint that resolves into a Decodable type.
	 - parameter request: The url request that defines the API request.
	 - parameter decoder: The data decoder that defines how to decode the response.
	 */
	init(request: URLRequest, decoder: DataDecoder) {
		self.request = request
		self.response = { try decoder.decode(Response.self, from: $0) }
	}
}

public extension Endpoint where Response == Void {
	/**
	 Create an endpoint that emits `()` then completes.
	 - parameter request: The url request that defines the API request.
	 */
	init(request: URLRequest) {
		self.request = request
		self.response = { _ in }
	}
}

public extension Endpoint where Response: Decodable {
	/**
	 Create an endpoint that handles a GraphQL operation.
	 - parameter op: The GraphQL operation being  used.
	 - parameter input: The input into the operation.
	 - Returns: An `Endpoint` that will handle the operation.
	 */
	static func operation<Input>(_ op: GraphQLOperation<Input, Response>,
	                             _ input: Input,
	                             authorization: String = "") -> Endpoint
		where Input: Encodable
	{
		Endpoint(
			request: createRequest(
				url: op.url,
				body: GraphQLBody(variables: input, query: op.operation),
				authorization: authorization
			),
			response: parseGraphQLResponse(data:)
		)
	}

	static func operation(_ op: GraphQLOperation<Void, Response>, authorization: String = "") -> Endpoint {
		Endpoint(
			request: createRequest(url: op.url, body: ["query": op.operation], authorization: authorization),
			response: parseGraphQLResponse(data:)
		)
	}
}
