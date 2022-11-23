//
//  UITextView+Placeholder.swift
//
//  Created by Daniel Tartaglia on 10/30/20.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import RxCocoa
import RxSwift
import UIKit

extension UITextView {
	func withPlaceholder(_ placeholder: String) {
		let didBeginEditing = rx.didBeginEditing
			.withLatestFrom(rx.text.orEmpty)
			.filter { $0 == placeholder }

		let didEndEditing = rx.didEndEditing
			.withLatestFrom(rx.text.orEmpty.asObservable())
			.filter { $0.isEmpty }

		_ = Observable.merge(
			didBeginEditing.map(to: ""),
			didEndEditing.map(to: placeholder)
		)
		.startWith(placeholder)
		.bind(to: rx.text)

		_ = Observable.merge(
			didBeginEditing.map(to: textColor),
			didEndEditing.map(to: tintColor)
		)
		.startWith(tintColor)
		.bind(to: rx.textColor)
	}
}

extension Reactive where Base: UITextView {
	var textColor: Binder<UIColor?> {
		Binder(base, binding: { view, color in
			view.textColor = color
		})
	}
}
