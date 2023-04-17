//
//  UITextView+Placeholder.swift
//
//  Created by Daniel Tartaglia on 30 Oct 2020.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import RxCocoa
import RxSwift
import UIKit

extension UITextView {
	func withPlaceholder(_ placeholder: String) {
		let label = {
			let result = UILabel(frame: bounds)
			result.text = placeholder
			result.numberOfLines = 0
			result.textColor = tintColor
			result.frame = result.frame.offsetBy(dx: 4, dy: 8)
			return result
		}()

		addSubview(label)

		_ = rx.observe(UIFont.self, "font")
			.map { $0 != nil ? $0 : UIFont.systemFont(ofSize: 12) }
			.take(until: rx.deallocating)
			.bind(onNext: { [weak self] font in
				label.font = font
				label.frame.size = label.sizeThatFits(self?.bounds.size ?? CGSize.zero)
			})

		_ = rx.text.orEmpty.map { !$0.isEmpty }
			.take(until: rx.deallocating)
			.bind(to: label.rx.isHidden)
	}
}
