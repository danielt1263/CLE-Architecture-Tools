//
//  Post.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 11/14/20.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import Cause_Logic_Effect
import Foundation

struct Post: Decodable, Identifiable {
	let id: Identifier<Int, Post>
	let title: String
	let body: String
	let userId: Int
}
