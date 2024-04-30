//
//  UserDefaults+Object.swift
//
//  Created by Daniel Tartaglia on 15 Apr 2024.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

extension UserDefaults {
	func current<Object>(_: Object.Type, key: String) -> Observable<Object?> where Object: Decodable {
		rx.observe(Data.self, key)
			.map { try $0.map { try decoder.decode(Object.self, from: $0) } }
			.catch { _ in Observable.just(nil) }
	}

	func save<Object>(_ object: Object?, key: String) throws where Object: Encodable {
		switch object {
		case .none:
			removeObject(forKey: key)
		case let .some(value):
			try set(encoder.encode(value), forKey: key)
		}
	}

	func object<Object>(_: Object.Type, key: String) -> Object? where Object: Decodable {
		data(forKey: key)
			.flatMap { try? decoder.decode(Object.self, from: $0) }
	}
}

private let decoder = {
	let result = JSONDecoder()
	result.dateDecodingStrategy = .iso8601
	return result
}()

private let encoder = {
	let result = JSONEncoder()
	result.dateEncodingStrategy = .iso8601
	return result
}()

