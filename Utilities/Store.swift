//
//  Store.swift
//
//  Created by Daniel Tartaglia on 3/11/2017.
//  Copyright © 2020 Daniel Tartaglia. MIT License
//

import Foundation
import RxSwift

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
