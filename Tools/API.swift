//
//  API.swift
//
//  Created by Daniel Tartaglia on 3/4/21.
//  Copyright © 2021 Daniel Tartaglia. MIT License.
//

import RxSwift
import Foundation
import Cause_Logic_Effect

public struct Endpoint<T> {
	let request: URLRequest
	let response: (Data) throws -> T
}

public final class API {
	private let session: URLSession
	private let activityIndicator: ActivityIndicator
	private let errorRouter: ErrorRouter

	public init(session: URLSession = .shared, activityIndicator: ActivityIndicator = ActivityIndicator(), errorRouter: ErrorRouter = ErrorRouter()) {
		self.session = session
		self.activityIndicator = activityIndicator
		self.errorRouter = errorRouter
	}

	var error: Observable<Error> {
		errorRouter.error
	}

	var isActive: Observable<Bool> {
		activityIndicator.asObservable()
	}

	func load<T>(_ endpoint: Endpoint<T>) -> Observable<T> {
		session.rx.data(request: endpoint.request)
			.map(endpoint.response)
			.trackActivity(activityIndicator)
			.rerouteError(errorRouter)
	}
}

public protocol EncoderType {
	var conentType: URLRequest.ContentType { get }
	func encode<T>(_ value: T) throws -> Data where T : Encodable
}

public protocol DecoderType {
	func decode<T: Decodable >(_ type: T.Type, from data: Data) throws -> T
}

extension URLRequest {
	public enum Method: String {
		case get = "GET"
		case post = "POST"
		case put = "PUT"
		case patch = "PATCH"
		case delete = "DELETE"
	}

	public enum ContentType: String {
		case json = "application/json"
		case xml = "application/xml"
		case urlencoded = "application/x-www-form-urlencoded"
	}

	public init(_ method: Method, url: URL, accept: ContentType? = nil, contentType: ContentType? = nil, body: Data? = nil, headers: [String: String] = [:], query: [String: String] = [:]) {
		var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
		components.queryItems = query.map { URLQueryItem(name: $0.0, value: $0.1) }
		var request = URLRequest(url: components.url!)
		if let accept = accept {
			request.setValue(accept.rawValue, forHTTPHeaderField: "Accept")
		}
		if let contentType = contentType {
			request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
		}
		for (key, value) in headers {
			request.setValue(value, forHTTPHeaderField: key)
		}
		request.httpMethod = method.rawValue

		// body *needs* to be the last property that we set, because of this bug: https://bugs.swift.org/browse/SR-6687
		request.httpBody = body
		self = request
	}

	public init<B: Encodable>(encoder: EncoderType, method: Method, url: URL, accept: ContentType?, body: B, headers: [String: String] = [:], query: [String: String] = [:]) {
		self.init(method, url: url, accept: accept, contentType: encoder.conentType, body: try! encoder.encode(body), headers: headers, query: query)
	}
}

extension Endpoint where T: Decodable {
	public init(request: URLRequest, decoder: DecoderType) {
		self.request = request
		self.response = { try decoder.decode(T.self, from: $0) }
	}
}

extension Endpoint where T == Void {
	init(request: URLRequest) {
		self.request = request
		self.response = { _ in }
	}
}

extension JSONEncoder: EncoderType {
	public var conentType: URLRequest.ContentType {
		.json
	}
}

extension PropertyListEncoder: EncoderType {
	public var conentType: URLRequest.ContentType {
		.xml
	}
}

extension JSONDecoder: DecoderType { }
extension PropertyListDecoder: DecoderType { }
