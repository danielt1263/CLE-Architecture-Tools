//
//  Reaction.swift
//
//  Created by Daniel Tartaglia on 13 Nov 2021.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

/**
 The various reaction functions are used to create feedback reactions for the `cycle` functions. All of them take a
 closure defining a `Payload` and a closure defining an `effect` that will happen in response to a request. The general
 rule with all of them is that if the `request` closure returns an approprate value, the effect closure will receive
 it. The rules around what an approiate value is depends on the type of the request object.
 */

public typealias Reaction<State, Input> = (Observable<(State, Input)>) -> Observable<Input>

public struct Payload<State, Input, Action, Result> {
	public let action: (State, Input) -> Action?
	public let result: (Action, Result) -> Input

	public init(action: @escaping (State, Input) -> Action?, result: @escaping (Action, Result) -> Input) {
		self.action = action
		self.result = result
	}
}

/**
 A reaction that allows multiple effects to occur at the same time.

 - parameter payload: Defines a payload such that when the `action` returns a non-nil value, the effect will be fired
 and its result will be modified by the payload's `result`.
 - parameter effect: Defines the effect that may be triggered.
 - returns: A reaction assembled from the payload and effect.
 */
public func mergable<S, I, A, R>(_ payload: Payload<S, I, A, R>,
								 effect: @escaping (A) -> Observable<R>) -> Reaction<S, I> {
	{ $0.compactMap(payload.action)
			.flatMap { Observable.combineLatest(Observable.just($0), effect($0)) }
			.map(payload.result)
	}
}

/**
 A reaction that will stop/interrupt an effect when a new effect is requested.

 - parameter payload: Defines a payload such that when the `action` returns a non-nil `Activity` value, any effect
 currently in process will be stopped. If the value is `restart` then a new effect wil be fired.
 - parameter stopsOn: A value that will cause any ongoing effect to cancel without starting a new effect. If `nil` then no such value exists.
 - parameter effect: Defines the effect that may be triggered.
 - returns: A reaction assembled from the payload and effect.
 */
public func stoppable<S, I, A, R>(_ payload: Payload<S, I, A, R>,
								  stopsOn: A? = nil,
								  effect: @escaping (A) -> Observable<R>) -> Reaction<S, I>
where A: Equatable {
	stoppable(payload, stopsOn: { $0 == stopsOn }, effect: effect)
}

/**
 A reaction that will stop/interrupt an effect when a new effect is requested.

 - parameter payload: Defines a payload such that when the `action` returns a non-nil `Activity` value, any effect
 currently in process will be stopped. If the value is `restart` then a new effect wil be fired.
 - parameter stopsOn: A predicate that defines what value will cause an ongoing effect to cancel without starting a new effect.
 - parameter effect: Defines the effect that may be triggered.
 - returns: A reaction assembled from the payload and effect.
 */
public func stoppable<S, I, A, R>(_ payload: Payload<S, I, A, R>,
								  stopsOn: @escaping (A) -> Bool,
								  effect: @escaping (A) -> Observable<R>) -> Reaction<S, I> {
	{ $0.compactMap(payload.action)
			.flatMapLatest { action in
				stopsOn(action)
				? Observable<(A, R)>.empty()
				: Observable.combineLatest(Observable.just(action), effect(action))
			}
			.map(payload.result)
	}
}

/**
 A reaction that will ignore requests while a particular effect is being handled.

 - parameter payload: Defines a payload such that when the `action` returns a non-nil value *and there isn't currently
 an effect in process*, the effect will be fired and its result will be modified by the payload's `result`.
 - parameter effect: Defines the effect that may be triggered.
 - returns: A reaction assembled from the payload and effect.
 */
public func ignorable<S, I, A, R>(_ payload: Payload<S, I, A, R>,
								  effect: @escaping (A) -> Observable<R>) -> Reaction<S, I> {
	{ $0.compactMap(payload.action)
			.flatMapFirst {
				Observable.combineLatest(Observable.just($0), effect($0))
			}
			.map(payload.result)
	}
}

/**
 A reaction that will stack requests such that only one will occur at a time but none will be ignored.

 - parameter payload: Defines a payload such that when the `action` returns a non-nil value, the effect will be added
 to the queue of requested effects. Its result will be modified by the payload's `result`.
 - parameter effect: Defines the effect that may be triggered.
 - returns: A reaction assembled from the payload and effect.
 */
public func stackable<S, I, A, R>(_ payload: Payload<S, I, A, R>,
								  effect: @escaping (A) -> Observable<R>) -> Reaction<S, I> {
	{ $0.compactMap(payload.action)
			.concatMap {
				Observable.combineLatest(Observable.just($0), effect($0))
			}
			.map(payload.result)
	}
}

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
