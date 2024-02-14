//
//  PhotosViewController.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/13/20.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import RxSwift
import UIKit

final class PhotosViewController: UIViewController {
	@IBOutlet var collectionView: UICollectionView!

	let disposeBag = DisposeBag()
}

final class PhotosViewCell: UICollectionViewCell {
	@IBOutlet var imageView: UIImageView!
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var activityIndicatorView: UIActivityIndicatorView!

	private(set) var disposeBag = DisposeBag()

	override func prepareForReuse() {
		super.prepareForReuse()
		disposeBag = DisposeBag()
	}
}
