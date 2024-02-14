//
//  PostViewController.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/13/20.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import RxSwift
import UIKit

final class PostViewController: UIViewController {
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var bodyLabel: UILabel!

	let disposeBag = DisposeBag()
}
