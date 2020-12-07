//
//  RxHelpers.swift
//  TCOMobile
//
//  Created by Daniel Tartaglia on 5/2/20.
//  Copyright © 2020 Trust Company of Oklohoma. All rights reserved.
//

import Foundation
import RxSwift

extension ObservableType {

	func map<T>(to: T) -> Observable<T> {
		return map { _ in to }
	}

	func compactMap<T>(to: T?) -> Observable<T> {
		return compactMap { _ in to }
	}
}

extension ObserverType {

	func onSuccess(_ element: Element) -> Void {
		onNext(element)
		onCompleted()
	}
}
