//
//  PhotoViewController.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/13/20.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import RxSwift
import UIKit

final class PhotoViewController: UIViewController {
	@IBOutlet var imageView: UIImageView!
	@IBOutlet var activityIndicatorView: UIActivityIndicatorView!

	let disposeBag = DisposeBag()
}
