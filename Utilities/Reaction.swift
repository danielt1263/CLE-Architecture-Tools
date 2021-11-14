//
//  Reaction.swift
//
//  Created by Daniel Tartaglia on 13 Nov 2021.
//  Copyright © 2021 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

/**
 The various reaction functions are used to create feedback reactions for the above `cycle` functions. All of
 them take a closure defining a `request` and a closure defining an `effect` that will happen in response
 to a request. The general rule with all of them is that if the `request` closure returns an approprate value, a
 new effect will be generated with that request. The rules around what an approiate value is depends on the
 type of the request object.
 */

public typealias Reaction<State, Input> = (Observable<(Input?, State)>) -> Observable<Input>

/**
 For this reaction, the request is a collection. If it is empty, no effect will be generated. If it contains at least one
 value, the effect closure will be called with the collection value.

 - Parameter request: A function that transforms the output to a Collection.
 - Parameter effect: A function that transforms Request into an Observable Action.
 - Returns: A new function that transforms Observable State into Observable Action.
 */
public func reaction<State, Request, Input>(
	request: @escaping (Input?, State) -> Request,
	effect: @escaping (Request) -> Observable<Input>
) -> Reaction<State, Input> where Request: Collection {
	{ $0.map(request)
		.flatMap { $0.isEmpty ? Observable.empty() : effect($0) }
	}
}

/**
 For this reaction, the request can be any type. If the `request` closure returns nil, no effect will be
 generated. If it contains a value, the effect closure will be called with the request.

 - Parameter request: A function that transforms State into an Optional Request.
 - Parameter effect: A function that transforms Request into an Observable Action.
 - Returns: A new function that transforms Observable State into Observable Action.
 */
public func reaction<State, Request, Input>(
	request: @escaping (Input?, State) -> Request?,
	effect: @escaping (Request) -> Observable<Input>
) -> Reaction<State, Input> {
	{ $0.compactMap(request)
		.flatMap(effect)
	}
}

/**
 For this reaction, the request is a Bool. If the `request` closure returns false, no effect will be generated. If
 it return true, the effect closure will be called.

 - Parameter request: A function that transforms State to a Bool.
 - Parameter effect: A function that transforms returns an Observable Action.
 - Returns: A new function that transforms Observable State into Observable Action.
 */
public func reaction<State, Input>(
	request: @escaping (Input?, State) -> Bool,
	effect: @escaping (()) -> Observable<Input>
) -> Reaction<State, Input> {
	{ $0.map(request)
		.flatMap { $0 ? effect(()) : Observable.empty() }
	}
}
