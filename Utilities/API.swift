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

	public func response<T>(_ endpoint: Endpoint<T>) -> Observable<T> {
		rawResponse(endpoint)
			.trackActivity(activityIndicator)
			.rerouteError(errorRouter)
	}

	public func resultResponse<T>(_ endpoint: Endpoint<T>) -> Observable<Result<T, Error>> {
		rawResponse(endpoint)
			.map { Result.success($0) }
			.catch { Observable.just(Result.failure($0)) }
	}

	public func rawResponse<T>(_ endpoint: Endpoint<T>) -> Observable<T> {
		session.rx.data(request: endpoint.request)
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
