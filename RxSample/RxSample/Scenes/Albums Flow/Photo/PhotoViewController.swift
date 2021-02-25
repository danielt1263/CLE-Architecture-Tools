//
//  PhotoViewController.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/13/20.
//	Copyright © 2020 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift

final class PhotoViewController: UIViewController {

	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	let disposeBag = DisposeBag()
}
