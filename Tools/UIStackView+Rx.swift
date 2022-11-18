//
//  UIStackView+Rx.swift
//
//  Created by Daniel Tartaglia on 24 Oct 2019.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UIStackView {
	func items<Source, Item>(initialView: UIView?)
	-> (_ source: Source)
	-> (_ viewForRow: @escaping (Int, Item) -> UIView)
	-> Disposable
	where Source: ObservableType, Source.Element == Array<Item>, Item: Identifiable {
		return { source in
			return { [base] viewForRow in
				var views = [Source.Element.Element.ID: UIView]()
				return source.subscribe(onNext: { items in
					let itemKeys = Set(items.map(\.id))
					for each in Set(views.keys).subtracting(itemKeys) {
						let view = views[each]!
						base.removeView(view: view)
						views.removeValue(forKey: each)
					}
					let itemIds = Dictionary(uniqueKeysWithValues: items.enumerated().map { ($0.element.id, $0.offset) })
					for each in itemKeys.subtracting(Set(views.keys)) {
						let view = base.insertView(index: itemIds[each]!, views: views, initialView: initialView, items: items, viewForRow: viewForRow)
						views[each] = view
					}
				})
			}
		}
	}
}

private extension UIStackView {
	func removeView(view: UIView) {
		removeArrangedSubview(view)
		view.removeFromSuperview()
	}

	func insertView<Item>(index: Int,
						  views: [Item.ID : UIView],
						  initialView: UIView?,
						  items: Array<Item>,
						  viewForRow: (Int, Item) -> UIView) -> UIView
	where Item: Identifiable {
		let beforeView = index > 0 ? views[items[index - 1].id] : initialView
		let view = viewForRow(index, items[index])
		if let beforeView {
			let viewIndex = arrangedSubviews.firstIndex(of: beforeView)!
			insertArrangedSubview(view, at: viewIndex + 1)
		}
		else {
			addArrangedSubview(view)
		}
		return view
	}
}
