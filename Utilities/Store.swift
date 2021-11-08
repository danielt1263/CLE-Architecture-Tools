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

public extension ObservableType {
	static func cancel(id: AnyHashable) -> Observable<Element> {
		Observable.deferred {
			disposeBagsLock.lock()
			disposeBags.removeValue(forKey: id)
			disposeBagsLock.unlock()
			return .empty()
		}
	}

	func cancellable(id: AnyHashable, cancelInFlight: Bool = false) -> Observable<Element> {
		Observable.deferred {
			if cancelInFlight {
				disposeBagsLock.sync {
					disposeBags.removeValue(forKey: id)
				}
			}
			let subject = PublishSubject<Element>()
			let disposable = self.subscribe(subject)
			disposeBagsLock.sync {
				if let bag = disposeBags[id] {
					bag.insert(disposable)
				}
				else {
					let bag = DisposeBag()
					bag.insert(disposable)
					disposeBags[id] = bag
				}
			}
			return subject
		}
	}
}

private var disposeBags: [AnyHashable: DisposeBag] = [:]
private let disposeBagsLock = NSRecursiveLock()

private extension NSRecursiveLock {
	func sync(_ callback: () -> Void) {
		lock()
		callback()
		unlock()
	}
}
