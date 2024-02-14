//
//  RxHelpers.swift
//
//  Created by Daniel Tartaglia on 02 May 2020.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
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
	func onSuccess(_ element: Element) {
		onNext(element)
		onCompleted()
	}
}
