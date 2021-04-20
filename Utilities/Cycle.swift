//
//  Cycle.swift
//
//  Created by Daniel Tartaglia on 2/26/21.
//  Copyright © 2021 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

public func cycle<Input, Output>(logic: @escaping (Observable<Input>) -> Observable<Output>, effects: @escaping (Observable<Output>) -> Observable<Input>) -> Observable<Output> {
	return Observable.using({ Cycle(logic: logic, effects: effects) }, observableFactory: { $0.output })
}

private final class Cycle<Input, Output>: Disposable {
	let output: Observable<Output>
	private let subject = ReplaySubject<Output>.create(bufferSize: 1)
	private let disposable: Disposable
	init(logic: (Observable<Input>) -> Observable<Output>, effects: (Observable<Output>) -> Observable<Input>) {
		disposable = logic(effects(subject))
			.bind(to: subject)
		output = subject.asObservable()
	}

	func dispose() {
		disposable.dispose()
	}
}
