//
//  Reaction.swift
//
//  Created by Daniel Tartaglia on 13 Nov 2021.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

/**
 The various reaction functions are used to create feedback reactions for the `cycle` functions. All of
 them take a closure defining a `request` and a closure defining an `effect` that will happen in response
 to a request. The general rule with all of them is that if the `request` closure returns an approprate value,
 the effect closure will receive it. The rules around what an approiate value is depends on the type of the
 request object.
 */

public typealias Reaction<State, Input> = (Observable<(State, Input)>) -> Observable<Input>

/**
 For this reaction, the request can be any type. If the `request` closure returns nil then `effect` will not
 receive a value. If it contains a value, the effect closure will receive the request.

 - parameter request: A function that transforms the Output into an Optional Request.
 - parameter effect: A function that should emit the results of the side effect.
 - returns: A new function that transforms Observable State into Observable Action.
 */
public func reaction<State, Input, Request>(
	request: @escaping (State, Input) -> Request?,
	effect: @escaping (Observable<Request>) -> Observable<Input>
) -> Reaction<State, Input> {
	{ effect($0.compactMap(request)) }
}

public func reaction<State, Input, Request>(
	request: @escaping (State, Input) -> Request?,
	effect: @escaping (Request) -> Observable<Input>
) -> Reaction<State, Input> {
	{ $0.compactMap(request).flatMap(effect) }
}

/**
 For this reaction, the request is a collection. If it is empty then `effect` will not receive it. If it contains at
 least one value, the effect closure will receive the request.

 - parameter request: A function that transforms the Output into a Collection.
 - parameter effect: A function that should emit the results of the side effect.
 - returns: A new function that transforms Observable State into Observable Action.
 */
public func reaction<State, Request, Input>(
	request: @escaping (State, Input) -> Request,
	effect: @escaping (Observable<Request>) -> Observable<Input>
) -> Reaction<State, Input> where Request: Collection {
	{ effect($0.map(request).filter { !$0.isEmpty }) }
}

public func reaction<State, Request, Input>(
	request: @escaping (State, Input) -> Request,
	effect: @escaping (Request) -> Observable<Input>
) -> Reaction<State, Input> where Request: Collection {
	{ $0.map(request).filter { !$0.isEmpty }.flatMap(effect) }
}

/**
 For this reaction, the request is a Bool. If it is false then `effect` will not receive a next event. If it returns
 true, the effect closure will receive a next event.

 - parameter request: A function that transforms the Output into a Bool.
 - parameter effect: A function that should emit the results of the side effect.
 - returns: A new function that transforms Observable State into Observable Action.
 */
public func reaction<State, Input>(
	request: @escaping (State, Input) -> Bool,
	effect: @escaping (Observable<()>) -> Observable<Input>
) -> Reaction<State, Input> {
	{ effect($0.map(request).filter { $0 }.map { _ in }) }
}

public func reaction<State, Input>(
	request: @escaping (State, Input) -> Bool,
	effect: @escaping () -> Observable<Input>
) -> Reaction<State, Input> {
	{ $0.map(request).filter { $0 }.map(to: ()).flatMap(effect) }
}
