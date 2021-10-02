//
//  Cycle.swift
//
//  Created by Daniel Tartaglia on 2/26/2021.
//  Copyright © 2021 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

/**
 A free function that creates an Observable of the Output of the Cycle type.
 
 - Parameter logic: A function that describes how to transform Observable Input to Output.
 - Parameter reactions: An array of functions that describe how to transform Observable Output back into Input.
 - Returns: An observable of type Output whose lifetime is bound to the internal Cycle type created by the `using` operator.
 */
public func cycle<Input, Output>(
    logic: @escaping (Observable<Input>) -> Observable<Output>,
    reactions: [(Observable<Output>) -> Observable<Input>]
) -> Observable<Output> {
	return Observable.using({ Cycle(logic: logic, effects: reactions) }, observableFactory: { $0.output })
}

/**
 A free function that creates an Observable of the Output of the Cycle type.
 
 - Parameter logic: A function that describes how to transform Observable Input to Output.
 - Parameter reactions: A single function that describes how to transform Observable Output back into Input.
 - Returns: An observable of type Output whose lifetime is bound to the internal Cycle type created by the `using` operator.
 */
public func cycle<Input, Output>(
    logic: @escaping (Observable<Input>) -> Observable<Output>,
    reaction: @escaping (Observable<Output>) -> Observable<Input>
) -> Observable<Output> {
	return Observable.using({ Cycle(logic: logic, effects: [reaction]) }, observableFactory: { $0.output })
}

/**
 A free function that given a "request" `(State) -> Request` and an "effect" `(Request) -> Observable<Action>`, returns a function transforming Observable State into Observable Action.

 - Parameter request: A function that transforms State to a Request.
 - Parameter effect: A function that transforms Request into an Observable Action.
 - Returns: A new function that transforms Observable State into Observable Action.
 */
public func reaction<State, Request, Action>(
    request: @escaping (State) -> Request,
    effect: @escaping (Request) -> Observable<Action>
) -> (Observable<State>) -> Observable<Action> where Request: Collection & Equatable {
	reaction(request: request, compare: { $0 == $1 }, effect: effect)
}

/**
 A free function that given a "request" `(State) -> Request?` and an "effect" `(Request) -> Observable<Action>`, returns a function transforming Observable State into Observable Action.

 - Parameter request: A function that transforms State into an Optional Request.
 - Parameter effect: A function that transforms Request into an Observable Action.
 - Returns: A new function that transforms Observable State into Observable Action.
 */
public func reaction<State, Request, Action>(
    request: @escaping (State) -> Request?,
    effect: @escaping (Request) -> Observable<Action>
) -> (Observable<State>) -> Observable<Action> where Request: Equatable {
	reaction(request: request, compare: { $0 == $1 }, effect: effect)
}

/**
 A free function that given a "request" `(State) -> Request`, a compare function `(Request, Request) -> Bool`, and an "effect" `(Request) -> Observable<Action>`, returns a function transforming Observable State into Observable Action.

 - Parameter request: A function that transforms State to a Request.
 - Parameter compare: A function that compares two Requests for equality. Comparison is used to avoid running the same Request twice through the effects.
 - Parameter effect: A function that transforms Request into an Observable Action.
 - Returns: A new function that transforms Observable State into Observable Action.
 */
public func reaction<State, Request, Action>(
    request: @escaping (State) -> Request,
    compare: @escaping (Request, Request) -> Bool,
    effect: @escaping (Request) -> Observable<Action>
) -> (Observable<State>) -> Observable<Action> where Request: Collection {
	{ $0.map(request)
		.distinctUntilChanged(compare)
		.flatMapLatest { $0.isEmpty ? Observable.empty() : effect($0) }
	}
}

/**
 A free function that given a "request" `(State) -> Request?`, a compare function `(Request?, Request?) -> Bool`, and an "effect" `(Request) -> Observable<Action>`, returns a function transforming Observable State into Observable Action.

 - Parameter request: A function that transforms State to an Optional Request.
 - Parameter compare: A function that compares two Optional Requests for equality. Comparison is used to avoid running the same Request twice through the effects.
 - Parameter effect: A function that transforms Request into an Observable Action.
 - Returns: A new function that transforms Observable State into Observable Action.
 */
public func reaction<State, Request, Action>(
    request: @escaping (State) -> Request?,
    compare: @escaping (Request?, Request?) -> Bool,
    effect: @escaping (Request) -> Observable<Action>
) -> (Observable<State>) -> Observable<Action> {
	{ $0.map(request)
		.distinctUntilChanged(compare)
		.flatMapLatest { (request) -> Observable<Action> in
			guard let request = request else { return Observable.empty() }
			return effect(request)
		}
	}
}

/**
 A free function that given a "request" `(State) -> Bool` and an "effect" `(Request) -> Observable<Action>`, returns a function transforming Observable State into Observable Action.

 - Parameter request: A function that transforms State to a Bool.
 - Parameter effect: A function that transforms returns an Observable Action.
 - Returns: A new function that transforms Observable State into Observable Action.
 */
public func reaction<State, Action>(
    request: @escaping (State) -> Bool,
    effect: @escaping (()) -> Observable<Action>
) -> (Observable<State>) -> Observable<Action> {
	{ $0.map(request)
		.distinctUntilChanged()
		.flatMapLatest { $0 ? effect(()) : Observable.empty() }
	}
}

/**
 Cycle
 
 A type whose purpose is to transform Input to Output and manage effects (or reactions) that "cycle" the Output, by transforming Output back into Input.

 - Parameter logic: A function that describes how to transform Observable Input to Output.
 - Parameter effects: An array of functions that describe how to transform Observable Output to Input.
 */
private final class Cycle<Input, Output>: Disposable {
	fileprivate let output: Observable<Output>
	private let disposable: Disposable

	init(logic: (Observable<Input>) -> Observable<Output>, effects: [(Observable<Output>) -> Observable<Input>]) {
		let subject = ReplaySubject<Output>.create(bufferSize: 1)
		disposable = logic(Observable.merge(effects.map { $0(subject) }))
			.bind(to: subject)
		output = subject.asObservable()
	}

	func dispose() {
		disposable.dispose()
	}
}
