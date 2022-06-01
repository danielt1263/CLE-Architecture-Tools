//
//  PhotoViewController.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/13/20.
//   Copyright © 2022 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift

final class PhotoViewController: UIViewController {

	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
	
	let disposeBag = DisposeBag()
}
