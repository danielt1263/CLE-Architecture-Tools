//
//  Store.swift
//
//  Created by Daniel Tartaglia on 11 Mar 2017.
//  Copyright © 2022 Daniel Tartaglia. MIT License
//

import Foundation
import RxSwift

public func cycle<State, Input, Environment>(inputs: [Observable<Input>], initialState: State, environment: Environment, reduce: @escaping (inout State, Input, Environment) -> Observable<Input>) -> Observable<State> {
	Observable.using({ _Store(inputs: inputs, initial: initialState, environment: environment, reducer: reduce) }, observableFactory: { $0.state })
}

@available(*, deprecated, message: "Use cycle(inputs:initialState:environment:reduce:) instead")
public final class Store<Action, State, Environment>: ObserverType {

	public let state: Observable<State>

	public init(initial: State, environment: Environment, reducer: @escaping (inout State, Action, Environment) -> Observable<Action>) {
		state = action
			.scan(into: initial) { [lock, action, disposeBag] in
				reducer(&$0, $1, environment)
					.subscribe(onNext: {
						lock.lock()
						action.onNext($0)
						lock.unlock()
					})
					.disposed(by: disposeBag)
			}
			.startWith(initial)
			.share(replay: 1)
	}

	deinit {
		lock.lock()
		action.onCompleted()
		lock.unlock()
	}

	public func on(_ event: Event<Action>) {
		if let element = event.element {
			lock.lock()
			action.onNext(element)
			lock.unlock()
		}
	}

	private let action = PublishSubject<Action>()
	private let lock = NSRecursiveLock()
	private let disposeBag = DisposeBag()
}

private final class _Store<State, Input, Environment>: Disposable {

	let state: Observable<State>
	private let action = PublishSubject<Input>()
	private let lock = NSRecursiveLock()
	private var disposeBag = DisposeBag()

	public init(inputs: [Observable<Input>], initial: State, environment: Environment, reducer: @escaping (inout State, Input, Environment) -> Observable<Input>) {
		state = action
			.scan(into: initial) { [lock, action, disposeBag] in
				reducer(&$0, $1, environment)
					.subscribe(onNext: {
						lock.lock()
						action.onNext($0)
						lock.unlock()
					})
					.disposed(by: disposeBag)
			}
			.startWith(initial)
			.share(replay: 1)

		Observable.merge(inputs)
			.bind(onNext: { [lock, action] element in
				lock.lock()
				action.onNext(element)
				lock.unlock()
			})
			.disposed(by: disposeBag)
	}

	func dispose() {
		disposeBag = DisposeBag()
	}
}
