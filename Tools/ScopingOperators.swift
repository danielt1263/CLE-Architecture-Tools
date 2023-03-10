//
//  ScopingOperators.swift
//
//  Created by Daniel Tartaglia on 21 May 2022.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

func apply<T>(_ t: T, _ fn: (inout T) -> Void) -> T {
	var a = t
	fn(&a)
	return a
}

func with<T, U>(_ t: T, _ fn: (inout T) -> U) -> U {
	var a = t
	let u = fn(&a)
	return u
}
