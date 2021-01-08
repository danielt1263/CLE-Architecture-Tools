//
//  Identifier.swift
//
//  Created by Daniel Tartaglia on 10/23/20.
//  Copyright © 2020 Haneke Design. MIT License
//

import Foundation

struct Identifier<T, ID>: RawRepresentable, Hashable where T: Codable & Hashable {
	let rawValue: T
}

extension Identifier: Codable {
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		rawValue = try container.decode(T.self)
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(rawValue)
	}
}
