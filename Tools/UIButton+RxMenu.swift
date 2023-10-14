//
//  UIButton+RxMenu.swift
//
//  Created by Daniel Tartaglia on 16 Nov 2022.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import RxSwift
import UIKit

@available(iOS 14.0, *)
extension UIButton {
	/**
	 Shows a drop-down/pull-down menu on a UIButton.

	 - parameter title: The menu's title.
	 - parameter subtitle: The subtitle of the menu.
	 - parameter image:  Image to be displayed alongside the menu's title.
	 - parameter identifier: The menu's unique identifier. Pass nil to use an auto-generated identifier.
	 - parameter options: The menu's options.
	 - parameter children:  The menu's action-based sub-elements and sub-menus.
	 - returns: An Observable that emits the index of the selected menu item.
	 */
	func addPulldownMenu(title: String = "",
						 subtitle: String = "",
						 image: UIImage? = nil,
						 identifier: UIMenu.Identifier? = nil,
						 options: UIMenu.Options = [],
						 children: [PulldownAction] = []) -> Observable<Int> {
		let result = PublishSubject<Int>()
		let childActions = children.enumerated().map { index, action in
			if #available(iOS 15.0, *) {
				return UIAction(
					title: action.title,
					subtitle: action.subtitle.isEmpty ? nil : action.subtitle,
					image: action.image,
					identifier: action.identifier,
					discoverabilityTitle: action.discoverabilityTitle.isEmpty ? nil : action.discoverabilityTitle,
					attributes: action.attributes,
					state: action.state,
					handler: { _ in
						result.onNext(index)
					}
				)
			} else {
				return UIAction(
					title: action.title,
					image: action.image,
					identifier: action.identifier,
					discoverabilityTitle: action.discoverabilityTitle.isEmpty ? nil : action.discoverabilityTitle,
					attributes: action.attributes,
					state: action.state,
					handler: { _ in
						result.onNext(index)
					}
				)
			}
		}

		let menu: UIMenu
		if #available(iOS 16.0, *) {
			menu = UIMenu(
				title: title,
				subtitle: subtitle.isEmpty ? nil : subtitle,
				image: image,
				identifier: identifier,
				options: options,
				children: childActions
			)
		} else {
			menu = UIMenu(
				title: title,
				image: image,
				identifier: identifier,
				options: options,
				children: childActions
			)
		}
		self.menu = menu
		self.showsMenuAsPrimaryAction = true
		return result
			.take(until: rx.deallocating)
	}
}

struct PulldownAction {
	var title: String = ""
	var subtitle: String = ""
	var image: UIImage? = nil
	var identifier: UIAction.Identifier? = nil
	var discoverabilityTitle: String = ""
	var attributes: UIMenuElement.Attributes = []
	var state: UIMenuElement.State = .off
}

