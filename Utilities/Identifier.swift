//
//  Identifier.swift
//
//  Created by Daniel Tartaglia on 10/23/2020.
//  Copyright © 2020 Daniel Tartaglia. MIT License
//

import Foundation

public struct Identifier<T, ID>: RawRepresentable, Hashable where T: Codable & Hashable {
	public let rawValue: T

	public init(rawValue: T) {
		self.rawValue = rawValue
	}
}

extension Identifier: Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		rawValue = try container.decode(T.self)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(rawValue)
	}
}

extension Identifier: Identifiable {
	public var id: Self {
		self
	}
}
