//
//  AlbumNavigationConnector.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 2/19/21.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import Cause_Logic_Effect
import RxCocoa
import RxSwift
import UIKit

extension UINavigationController {
	func connectAlbums() {
		let albums = UITableViewController().scene { $0.connectAlbums() }
		viewControllers = [albums.controller]

		let photoURL = albums.action
			.flatMapFirst(pushScene(on: self, animated: true) { album in
				PhotosViewController.scene { $0.connect(with: album) }
			})

		_ = photoURL
			.take(until: rx.deallocating)
			.bind(onNext: showDetailScene { url in
				PhotoViewController.scene { $0.connect(url: url) }
			})
	}
}
