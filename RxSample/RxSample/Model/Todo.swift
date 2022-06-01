//
//  Todo.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 11/15/20.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import Cause_Logic_Effect
import Foundation

struct Todo: Decodable, Identifiable {
	let id: Identifier<Int, Todo>
	let title: String
	let userId: Int
}
