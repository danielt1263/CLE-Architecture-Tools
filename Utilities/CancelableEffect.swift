//
//  CancelableEffect.swift
//
//
//  Created by Daniel Tartaglia on 13 Nov 2021.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//  Adapted from https://github.com/pointfreeco/swift-composable-architecture/blob/main/Sources/ComposableArchitecture/Effects/Cancellation.swift
//

import Foundation
import RxSwift

/**
 The operators here can be used to make a cancelable effect for a Reaction. You must provide an `id` of some
 `Hashable` type.
 */
public extension ObservableType {
	/**
	 A `cancel` Observable with an `id` will cancel every effect that is in flight which was created with that `id`.

	 - parameter id: The identifier of the effect(s) you wish to cancel.
	 - returns: An Observable that will cancel all in-flight effects that were chained to the `calcellable(id:)`
	 operator.
	 */
	static func cancel(id: AnyHashable) -> Observable<Element> {
		Observable.deferred {
			disposeBagsLock.lock()
			disposeBags.removeValue(forKey: id)
			disposeBagsLock.unlock()
			return .empty()
		}
	}

	/**
	 Adding the `cancelable` operator to an effect will give it an `id` which can be used with
	 `cancel(id:)`.

	 - parameter id: The identifier of the effect for later possible cancelation.
	 - parameter cancelInFlight: If true, all effect that are currently in flight with this `id` will be
	 canceled before this effect starts.
	 */
	func cancelable(id: AnyHashable, cancelInFlight: Bool = false) -> Observable<Element> {
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
