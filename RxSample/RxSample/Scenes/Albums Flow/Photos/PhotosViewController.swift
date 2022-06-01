//
//  PhotosViewController.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/13/20.
//   Copyright © 2022 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift

final class PhotosViewController: UIViewController {

	@IBOutlet weak var collectionView: UICollectionView!
	
	let disposeBag = DisposeBag()
}

final class PhotosViewCell: UICollectionViewCell {
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

	private (set) var disposeBag = DisposeBag()

	override func prepareForReuse() {
		super.prepareForReuse()
		disposeBag = DisposeBag()
	}
}
