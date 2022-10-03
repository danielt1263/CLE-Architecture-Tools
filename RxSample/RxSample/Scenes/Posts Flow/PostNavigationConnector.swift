//
//  PostNavigationConnector.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 2/20/21.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import Cause_Logic_Effect
import RxCocoa
import RxSwift
import UIKit

extension UINavigationController {
	func connectPosts() {
		let posts = UITableViewController().scene { $0.connectPosts() }
		viewControllers = [posts.controller]

		_ = posts.action
			.take(until: rx.deallocating)
			.bind(onNext: showDetailScene { post in
				PostViewController().scene { $0.connect(post: post) }
			})
	}
}
