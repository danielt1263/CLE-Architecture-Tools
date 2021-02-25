//
//  ServerAPI.swift
//  ION
//
//  Created by Daniel Tartaglia on 6/28/19.
//  Copyright © 2019 Daniel Tartaglia. MIT License.
//

import Cause_Logic_Effect
import Foundation
import RxSwift
import RxCocoa

struct Endpoint<T> {
	let request: URLRequest
	let response: (Data) throws -> T
}

extension Endpoint where T: Decodable {
	init(request: URLRequest) {
		self.request = request
		self.response = { try jsonDecoder.decode(T.self, from: $0) }
	}
}

extension Endpoint where T == Void {
	init(request: URLRequest) {
		self.request = request
		self.response = { _ in }
	}
}

let activityIndicator = ActivityIndicator()
let errorRouter = ErrorRouter()

let jsonDecoder: JSONDecoder = {
	let result = JSONDecoder()
	result.keyDecodingStrategy = .convertFromSnakeCase
	return result
}()

func apiResponse<T>(from endpoint: Endpoint<T>) -> Observable<T> {
	URLSession.shared.rx.data(request: endpoint.request)
		.map(endpoint.response)
		.trackActivity(activityIndicator)
		.rerouteError(errorRouter)
}

extension URLComponents {
	mutating func addQueryItem<T>(name: String, param: T?, formatted: (T) -> String) {
		guard let param = param else { return }
		let queryItem = URLQueryItem(name: name, value: formatted(param))
		if queryItems == nil {
			queryItems = [queryItem]
		}
		else {
			queryItems!.append(queryItem)
		}
	}
}
