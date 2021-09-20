//
//  API.swift
//
//  Created by Daniel Tartaglia on 3/4/21.
//  Copyright © 2021 Daniel Tartaglia. MIT License.
//

import RxSwift
import Foundation

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

	func response<T>(_ endpoint: Endpoint<T>) -> Observable<T> {
		session.rx.data(request: endpoint.request)
			.map(endpoint.response)
			.trackActivity(activityIndicator)
			.rerouteError(errorRouter)
	}

	func resultResponse<T>(_ endpoint: Endpoint<T>) -> Observable<Result<T, Error>> {
		session.rx.data(request: endpoint.request)
			.trackActivity(activityIndicator)
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
	init(request: URLRequest) {
		self.request = request
		self.response = { _ in }
	}
}
