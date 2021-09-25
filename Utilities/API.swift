//
//  API.swift
//
//  Created by Daniel Tartaglia on 3/4/2021.
//  Copyright © 2021 Daniel Tartaglia. MIT License.
//

import RxSwift
import Foundation

public struct Endpoint<T> {
	public let request: URLRequest
	public let response: (Data) throws -> T

	public init(request: URLRequest, response: @escaping (Data) throws -> T) {
		self.request = request
		self.response = response
	}
}

/**
 A high level abstraction around URLSession for making requests, tracking network activity and handling errors.
 */
public final class API {
	private let session: URLSession
	private let activityIndicator: ActivityIndicator
	private let errorRouter: ErrorRouter

	public init(session: URLSession = .shared, activityIndicator: ActivityIndicator = ActivityIndicator(), errorRouter: ErrorRouter = ErrorRouter()) {
		self.session = session
		self.activityIndicator = activityIndicator
		self.errorRouter = errorRouter
	}

	public var error: Observable<Error> {
		errorRouter.error
	}

	public var isActive: Observable<Bool> {
		activityIndicator.asObservable()
	}

	/**
	 Transforms an Endpoint<T> into an Observable<T> by making requests to the local URLSession.

	 * Network activity is tracked by the local activity indicator.
	 * Errors from the Observable are routed to the local error router.

	 - Parameter endpoint: The API endpoint for which a request is made.
	 - Returns: An Observable of the response type whose network activity and errors are handled automatically. This Observable will not emit an error event.
	 */
	public func response<T>(_ endpoint: Endpoint<T>) -> Observable<T> {
		rawResponse(endpoint)
			.rerouteError(errorRouter)
	}

	/**
	 Transforms an Endpoint<Void> into an Observable<Bool> for making requests to the local URLSession.

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
	 Transforms an Endpoint<T> into an Observable<T?> for making requests to the local URLSession.

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
	 Transforms an Endpoint<T> into an Observable of Result<T, Error> for making requests to the local URLSession.

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
	 Transforms an Endpoint<T> into an Observable<T> for making requests to the local URLSession.

	 * Network activity is tracked by the local activity indicator.
	 * An error will emit if the network request fails.

	 - Parameter endpoint: The API endpoint to which a request is made.
	 - Returns: A Observable of the response type.
	 */
	public func rawResponse<T>(_ endpoint: Endpoint<T>) -> Observable<T> {
		session.rx.data(request: endpoint.request)
			.trackActivity(activityIndicator)
			.map(endpoint.response)
	}
}

extension Endpoint where T: Decodable {
	public init(request: URLRequest, decoder: DataDecoder) {
		self.request = request
		self.response = { try decoder.decode(T.self, from: $0) }
	}
}

extension Endpoint where T == Void {
	public init(request: URLRequest) {
		self.request = request
		self.response = { _ in }
	}
}
