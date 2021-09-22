//
//  API.swift
//
//  Created by Daniel Tartaglia on 3/4/21.
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
     Transforms an Endpoint<T> into an Observable<T> for making requests to the local URLSession.

     * Network activity is tracked by the local activity indicator.
     * Errors from the Observable are routed to the local error router.
     
    - Parameter endpoint: The API endpoint to which a request is made.
    - Returns: A Observable of the response type whose network activity and errors are handled automatically.
     */
	public func response<T>(_ endpoint: Endpoint<T>) -> Observable<T> {
		session.rx.data(request: endpoint.request)
			.map(endpoint.response)
			.trackActivity(activityIndicator)
			.rerouteError(errorRouter)
	}

    /**
     Transforms an Endpoint<T> into an Observable of Result<T, Error> for making requests to the local URLSession.
     
     - Parameter endpoint: The API endpoint to which a request is made.
     - Returns: A Observable Result of the response type.
     */
	public func resultResponse<T>(_ endpoint: Endpoint<T>) -> Observable<Result<T, Error>> {
		session.rx.data(request: endpoint.request)
			.map { try Result.success(endpoint.response($0)) }
			.catch { Observable.just(Result.failure($0)) }
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
