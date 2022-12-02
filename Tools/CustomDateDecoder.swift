//
//  CustomDateDecoder.swift
//
//  Created by Daniel Tartaglia on 02 Dec 2022.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

enum CustomDateDecodingError: Error {
	case unableToDecode(String)
	case conflictingDecodeValues([Date])
}

func customDateDecoder(formatters: DateFormatter...) -> (Decoder) throws -> Date {
	customDateDecoder(formatters: formatters)
}

func customDateDecoder(formatters: [DateFormatter]) -> (Decoder) throws -> Date {
	{ decoder in
		let container = try decoder.singleValueContainer()
		let text = try container.decode(String.self)
		let dates = formatters.compactMap({ $0.date(from: text) })
		guard !dates.isEmpty else {
			throw CustomDateDecodingError.unableToDecode(text)
		}
		guard dates.allSatisfy({ $0 == dates.first }) else {
			throw CustomDateDecodingError.conflictingDecodeValues(dates)
		}
		return dates.first!
	}
}
