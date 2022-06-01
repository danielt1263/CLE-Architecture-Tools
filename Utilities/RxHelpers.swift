//
//  RxHelpers.swift
//
//  Created by Daniel Tartaglia on 5/2/2020.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

public extension ObservableType {

	func map<T>(to: T) -> Observable<T> {
		return map { _ in to }
	}

	func compactMap<T>(to: T?) -> Observable<T> {
		return compactMap { _ in to }
	}
}

public extension ObserverType {

	func onSuccess(_ element: Element) -> Void {
		onNext(element)
		onCompleted()
	}
}
