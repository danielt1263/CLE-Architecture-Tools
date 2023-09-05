//
//  Cycle.swift
//
//  Created by Daniel Tartaglia on 25 Feb 2021.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

/**
 This function helps the developer setup a state machine. The `reaction`s attached to the machine will recieve the most
 recent input along with the state _before_ applying the input. The return observable however will emit the state
 _after_ applying the input. For those who are curious, this state machine acts like a Mealy machine for `reaction`s,
 and a Moor machine for external output.

 - Parameter inputs: An array of external inputs that drive the machine.
 - Parameter initialState: The starting state of the machine.
 - Parameter reduce: The function that defines how state transitions.
 - Parameter effects: Side effects that feed back into the state machine.
 - Returns: An Observable that emits the state of the machine as it updates.
 */
public func cycle<State, Input>(
    inputs: [Observable<Input>],
    initialState: State,
    reduce: @escaping (inout State, Input) -> Void,
    effects: [Reaction<State, Input>],
    scheduler: ImmediateSchedulerType = MainScheduler.asyncInstance
) -> Observable<State> {
    cycle(
        input: Observable.merge(inputs),
        logic: { input in
            let sharedInput = input
                .share(replay: 1)
            return Observable.zip(sharedInput.scan(into: initialState, accumulator: reduce), sharedInput)
        },
        effect: { action in
            Observable.merge(effects.map { $0(action) })
        },
        scheduler: scheduler
    )
    .map { $0.0 }
    .startWith(initialState)
}

/**
 This function helps the developer setup a feedback loop. It allows the minimum separation of logic and effects without
 making any assumptions about how the logic or effects are handled.

 - Parameter input: An external input that starts the feedback loop.
 - Parameter logic: The function that defines the logic of the feedback loop.
 - Parameter effect: The function that defines the side effects that feed back into the loop.
 - Returns: An Observable that emits the state of the machine as it updates.
 */
public func cycle<Output, Input>(
    input: Observable<Input>,
    logic: @escaping (Observable<Input>) -> Observable<Output>,
    effect: @escaping (Observable<Output>) -> Observable<Input>,
    scheduler: ImmediateSchedulerType = MainScheduler.asyncInstance
) -> Observable<Output> {
    Observable.using(
        Resource.build(PublishSubject<Input>()),
        observableFactory: Resource.createObservable { disposeBag, subject in
            let sharedInput = input
                .share(replay: 1)
            let state = logic(Observable.merge(sharedInput, subject))
                .share(replay: 1)
            effect(state)
                .take(until: sharedInput.takeLast(1))
                .observe(on: scheduler)
                .subscribe(subject)
                .disposed(by: disposeBag)
            return state
        }
    )
}
