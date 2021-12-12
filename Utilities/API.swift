//
//  API.swift
//
//  Created by Daniel Tartaglia on 4 Mar 2021.
//  Copyright © 2021 Daniel Tartaglia. MIT License.
//

import RxSwift
import Foundation

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

/**
 A high level abstraction around URLSession for making requests, tracking network activity and handling
 errors.
 */
public final class API {
	private let activityIndicator: ActivityTracker
	private let errorRouter: ErrorRouter
	private var data: (URLRequest) -> Observable<Data>

	public init(session: URLSession = .shared, activityIndicator: ActivityTracker = ActivityTracker(), errorRouter: ErrorRouter = ErrorRouter()) {
		self.activityIndicator = activityIndicator
		self.errorRouter = errorRouter
		self.data = session.rx.data(request:)
	}

	/**
	 All requests thta fail (except for those made with `rawRequest` will have their errors routed to this
	 Observable.
	 */
	public var error: Observable<Error> {
		errorRouter.error
	}

	/**
	 All requests made with this object will have their in flight status tracked.
	 */
	public var isActive: Observable<Bool> {
		activityIndicator.isActive
	}

	/**
	 Transforms an Endpoint<Response> into an Observable<Response> by making requests to the local
	 URLSession.

	 * Network activity is tracked by the local activity indicator.
	 * Errors from the Observable are routed to the local error router.

	 - Parameter endpoint: The API endpoint for which a request is made.
	 - Returns: An Observable of the response type whose network activity and errors are handled
	 automatically. This Observable will not emit an error event.
	 */
	public func response<T>(_ endpoint: Endpoint<T>) -> Observable<T> {
		rawResponse(endpoint)
			.rerouteError(errorRouter)
	}

	/**
	 Transforms an Endpoint<Void> into an Observable<Bool> for making requests to the local
	 URLSession.

	 * Network activity is tracked by the local activity indicator.
	 * Errors from the network request are routed to the local error router and the response will emit false.

	 - Parameter endpoint: The API endpoint to which a request is made.
	 - Returns: An Observable of `Bool` that will not emit an error event.
	 */
	public func successResponse(_ endpoint: Endpoint<Void>) -> Observable<Bool> {
		rawResponse(endpoint)
			.do(onError: { [errorRouter] in errorRouter.routeError($0) })
				.map(to: true)
				.catch { _ in Observable.just(false) }
	}

	/**
	 Transforms an Endpoint<Response> into an Observable<Response?> for making requests to the
	 local URLSession.

	 * Network activity is tracked by the local activity indicator.
	 * Errors from the Observable are routed to the local error router and the response will emit nil.

	 - Parameter endpoint: The API endpoint to which a request is made.
	 - Returns: A Observable of the response type that will not emit an error event.
	 */
	public func successResponse<T>(_ endpoint: Endpoint<T>) -> Observable<T?> {
		rawResponse(endpoint)
			.do(onError: { [errorRouter] in errorRouter.routeError($0) })
				.map { Optional.some($0) }
				.catch { _ in Observable.just(nil) }
	}

	/**
	 Transforms an Endpoint<Response> into an Observable of Result<Response, Error> for making
	 requests to the local URLSession.

	 * Network activity is tracked by the local activity indicator.

	 - Parameter endpoint: The API endpoint to which a request is made.
	 - Returns: A Observable Result of the response type. This Observable will not emit an error event.
	 */
	public func resultResponse<T>(_ endpoint: Endpoint<T>) -> Observable<Result<T, Error>> {
		rawResponse(endpoint)
			.map { Result.success($0) }
			.catch { Observable.just(Result.failure($0)) }
	}

	/**
	 Transforms an Endpoint<Response> into an Observable<Response> for making requests to the local
	 URLSession.

	 * Network activity is tracked by the local activity indicator.
	 * An error will emit if the network request fails.

	 - Parameter endpoint: The API endpoint to which a request is made.
	 - Returns: A Observable of the response type.
	 */
	public func rawResponse<T>(_ endpoint: Endpoint<T>) -> Observable<T> {
		data(endpoint.request)
			.trackActivity(activityIndicator)
			.map(endpoint.response)
	}

	/**
	 Allows client to change the source that the above methods use for retrieving data. Use this method
	 when you want to, for example, stub out a network request in favor of responding with local data while
	 testing.
	 - Parameter data: The function that should be used by the above methods to make network
	 requests. All of the above methods will ultimate use the function passed in.
	 */
	public func setSource(_ data: @escaping (URLRequest) -> Observable<Data>) {
		self.data = data
	}
}

extension Endpoint where Response: Decodable {
	public init(request: URLRequest, decoder: DataDecoder) {
		self.request = request
		self.response = { try decoder.decode(Response.self, from: $0) }
	}
}

extension Endpoint where Response == Void {
	public init(request: URLRequest) {
		self.request = request
		self.response = { _ in }
	}
}
