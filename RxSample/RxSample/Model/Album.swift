//
//  Album.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 11/15/20.
//  Copyright © 2020 Daniel Tartaglia. MIT License.
//

import Cause_Logic_Effect
import Foundation

struct Album: Decodable, Identifiable {
	let id: Identifier<Int, Album>
	let title: String
	let userId: Int
}

struct Photo: Decodable, Identifiable {
	let id: Identifier<Int, Photo>
	let albumId: Int
	let title: String
	let thumbnailUrl: URL
	let url: URL
}
