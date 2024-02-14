//
//  Cycle.swift
//
//  Created by Daniel Tartaglia on 25 Feb 2021.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

/**
 Helps set up a state machine.

 The `reaction`s attached to the machine will recieve the most recent input along with the state _before_ applying the
 input. The return observable however will emit the state _after_ applying the input.

 For those who are curious, this state machine acts like a Mealy machine for `reaction`s, but a Moore machine for
 external output.

 - parameter inputs: An array of external inputs that drive the machine.
 - parameter initialState: The starting state of the machine.
 - parameter reduce: The function that defines how state transitions.
 - parameter reaction: A side effect that feeds back into the state machine.
 - returns: An Observable that emits the state of the machine as it updates.
 */
public func cycle<State, Input>(
	inputs: [Observable<Input>],
	initialState: State,
	reduce: @escaping (inout State, Input) -> Void,
	reaction: @escaping Reaction<State, Input>
) -> Observable<State> {
	cycle(inputs: inputs, initialState: initialState, reduce: reduce, reactions: [reaction])
}

/**
 Helps set up a state machine.

 The `reaction`s attached to the machine will recieve the most recent input along with
 the state _before_ applying the input. The return observable however will emit the state _after_ applying the input.
 For those who are curious, this state machine acts like a Mealy machine for `reaction`s, but a Moore machine for
 external output.

 - parameter inputs: An external input that drives the machine.
 - parameter initialState: The starting state of the machine.
 - parameter reduce: The function that defines how state transitions.
 - parameter reaction: A side effect that feeds back into the state machine.
 - returns: An Observable that emits the state of the machine as it updates.
 */
public func cycle<State, Input>(
	input: Observable<Input>,
	initialState: State,
	reduce: @escaping (inout State, Input) -> Void,
	reaction: @escaping Reaction<State, Input>
) -> Observable<State> {
	cycle(inputs: [input], initialState: initialState, reduce: reduce, reactions: [reaction])
}

/**
 Helps set up a state machine. The `reaction`s attached to the machine will recieve the most recent input along with
 the state _before_ applying the input. The return observable however will emit the state _after_ applying the input.
 For those who are curious, this state machine acts like a Mealy machine for `reaction`s, but a Moore machine for
 external output.

 - parameter input: An external input that drives the machine.
 - parameter initialState: The starting state of the machine.
 - parameter reduce: The function that defines how state transitions.
 - parameter reaction: A side effect that feeds back into the state machine.
 - returns: An Observable that emits the state of the machine as it updates.
 */
public func cycle<State, Input>(
	input: Observable<Input>,
	initialState: State,
	reduce: @escaping (inout State, Input) -> Void,
	reactions: [Reaction<State, Input>]
) -> Observable<State> {
	cycle(inputs: [input], initialState: initialState, reduce: reduce, reactions: reactions)
}

/**
 Helps set up a state machine. The `reaction`s attached to the machine will recieve the most recent input along with
 the state _before_ applying the input. The return observable however will emit the state _after_ applying the input.
 For those who are curious, this state machine acts like a Mealy machine for `reaction`s, but a Moore machine for
 external output.

 - parameter inputs: An array of external inputs that drive the machine.
 - parameter initialState: The starting state of the machine.
 - parameter reduce: The function that defines how state transitions.
 - parameter reaction: An array of side effects that feeds back into the state machine.
 - returns: An Observable that emits the state of the machine as it updates.
 */
public func cycle<State, Input>(
	inputs: [Observable<Input>],
	initialState: State,
	reduce: @escaping (inout State, Input) -> Void,
	reactions: [Reaction<State, Input>]
) -> Observable<State> {
	return Observable.using(
		Resource.build(PublishSubject<Input>()),
		observableFactory: Resource.createObservable { disposeBag, subject in
			let outsideInputs = Observable.merge(inputs)
				.share(replay: 1)
			let allInputs = Observable.merge(outsideInputs, subject)
				.share(replay: 1)
			let state = allInputs
				.scan(into: initialState, accumulator: reduce)
				.startWith(initialState)
				.share(replay: 1)
			let reactionInput = Observable.zip(state, allInputs)

			Observable.merge(reactions.map { $0(reactionInput) })
				.subscribe(subject)
				.disposed(by: disposeBag)
			return state
				.take(until: outsideInputs.materialize().takeLast(1))
		}
	)
}

/**
 Helps set up a feedback loop.

 - parameter input: External inputs that drive the system.
 - parameter logic: A function that converts inputs into outputs.
 - parameter effect: A function that feeds inputs back into itself based on outputs.
 - returns: An Observable that emits the outputs.
 */
public func cycle<Output, Input>(input: Observable<Input>,
                                 logic: @escaping (Observable<Input>) -> Observable<Output>,
                                 effect: @escaping (Observable<Output>) -> Observable<Input>) -> Observable<Output>
{
	Observable.using(
		Resource.build(PublishSubject<Input>()),
		observableFactory: Resource.createObservable { disposeBag, subject in
			let sharedInput = input
				.share(replay: 1)
			let state = logic(Observable.merge(sharedInput, subject))
				.share(replay: 1)
			effect(state)
				.take(until: sharedInput.materialize().takeLast(1))
				.subscribe(subject)
				.disposed(by: disposeBag)
			return state
		}
	)
}
