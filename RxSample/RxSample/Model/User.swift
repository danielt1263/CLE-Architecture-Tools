//
//  User.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 11/14/20.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import Cause_Logic_Effect
import Foundation

struct User: Codable, Identifiable {
	let id: Identifier<Int, User>
	let name: String
	let address: Address
	let company: Company
	let email: String
	let phone: String
	let username: String
	let website: String
}

struct Address: Codable {
	let city: String
	let geo: Geo
	let street: String
	let suite: String
	let zipcode: String
}

struct Company: Codable {
	let bs: String
	let catchPhrase: String
	let name: String
}

struct Geo: Codable {
	let lat: String
	let lng: String
}
