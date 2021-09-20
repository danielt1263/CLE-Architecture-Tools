//
//  Cycle.swift
//
//  Created by Daniel Tartaglia on 2/26/21.
//  Copyright © 2021 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

public func cycle<Input, Output>(logic: @escaping (Observable<Input>) -> Observable<Output>, reactions: [(Observable<Output>) -> Observable<Input>]) -> Observable<Output> {
	return Observable.using({ Cycle(logic: logic, effects: reactions) }, observableFactory: { $0.output })
}

public func cycle<Input, Output>(logic: @escaping (Observable<Input>) -> Observable<Output>, reaction: @escaping (Observable<Output>) -> Observable<Input>) -> Observable<Output> {
	return Observable.using({ Cycle(logic: logic, effects: [reaction]) }, observableFactory: { $0.output })
}

public func reaction<State, Request, Action>(request: @escaping (State) -> Request, effect: @escaping (Request) -> Observable<Action>) -> (Observable<State>) -> Observable<Action> where Request: Collection & Equatable {
	reaction(request: request, compare: { $0 == $1 }, effect: effect)
}

public func reaction<State, Request, Action>(request: @escaping (State) -> Request?, effect: @escaping (Request) -> Observable<Action>) -> (Observable<State>) -> Observable<Action> where Request: Equatable {
	reaction(request: request, compare: { $0 == $1 }, effect: effect)
}

public func reaction<State, Request, Action>(request: @escaping (State) -> Request, compare: @escaping (Request, Request) -> Bool, effect: @escaping (Request) -> Observable<Action>) -> (Observable<State>) -> Observable<Action> where Request: Collection {
	{ $0.map(request)
		.distinctUntilChanged(compare)
		.flatMapLatest { $0.isEmpty ? Observable.empty() : effect($0) }
	}
}

public func reaction<State, Request, Action>(request: @escaping (State) -> Request?, compare: @escaping (Request?, Request?) -> Bool, effect: @escaping (Request) -> Observable<Action>) -> (Observable<State>) -> Observable<Action> {
	{ $0.map(request)
		.distinctUntilChanged(compare)
		.flatMapLatest { (request) -> Observable<Action> in
			guard let request = request else { return Observable.empty() }
			return effect(request)
		}
	}
}

public func reaction<State, Action>(request: @escaping (State) -> Bool, effect: @escaping (()) -> Observable<Action>) -> (Observable<State>) -> Observable<Action> {
	{ $0.map(request)
		.distinctUntilChanged()
		.flatMapLatest { $0 ? effect(()) : Observable.empty() }
	}
}

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
