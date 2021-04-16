//
//  Resource.swift
//
//  Created by Daniel Tartaglia on 3/4/21.
//  Copyright © 2021 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

struct Resource<T> {
	let request: URLRequest
	let response: (Data) throws -> T
}

final class API {
	private let session: URLSession
	private let activityIndicator: ActivityIndicator
	private let errorRouter: ErrorRouter

	init(session: URLSession, activityIndicator: ActivityIndicator, errorRouter: ErrorRouter) {
		self.session = session
		self.activityIndicator = activityIndicator
		self.errorRouter = errorRouter
	}

	func load<T>(_ resource: Resource<T>) -> Observable<T> {
		session.rx.data(request: resource.request)
			.map(resource.response)
			.trackActivity(activityIndicator)
			.rerouteError(errorRouter)
	}
}

extension Resource where T: Decodable {
	init(request: URLRequest, decoder: JSONDecoder) {
		self.request = request
		self.response = { try decoder.decode(T.self, from: $0) }
	}
}

extension Resource where T == Void {
	init(request: URLRequest) {
		self.request = request
		self.response = { _ in }
	}
}
