//
//  SplitConnector.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/11/20.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift
import RxCocoa

extension UISplitViewController {

	func connect() {
		delegate = SplitViewControllerDelegate.instance

		let tab = UITabBarController().configure { $0.connect() }
		let placeholder = UIViewController()
			.configure {
				let imageView = apply(UIImageView()) {
					$0.image = UIImage(named: "EmptyViewBackground")
					$0.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleRightMargin, .flexibleBottomMargin]
					$0.sizeToFit()
				}

				imageView.center = CGPoint(x: $0.view.bounds.midX, y: $0.view.bounds.midY)
				$0.view.addSubview(imageView)
			}
		viewControllers = [tab, UINavigationController(rootViewController: placeholder)]
	}
}
