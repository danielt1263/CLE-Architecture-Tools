//
//  PostConnector.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/13/20.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift
import RxCocoa

extension PostViewController {
	func connect(post: Post) -> Observable<Never> {
		titleLabel.text = post.title
		bodyLabel.text = post.body

		return Observable.never()
			.take(until: rx.deallocating)
	}
}
