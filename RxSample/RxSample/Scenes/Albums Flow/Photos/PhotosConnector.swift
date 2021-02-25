//
//  PhotosConnector.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/13/20.
//	Copyright © 2020 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift
import RxCocoa

extension PhotosViewController {
	func connect(with album: Album) -> Observable<URL> {

		let photos = Observable.just(album.id)
			.flatMapLatest {
				apiResponse(from: .getPhotos(id: $0))
			}
			.share()

		photos
			.bind(to: collectionView.rx.items(cellIdentifier: "Cell", cellType: PhotosViewCell.self)) { _, item, cell in
				cell.bind(with: item)
			}
			.disposed(by: disposeBag)

		return collectionView.rx.itemSelected
			.withLatestFrom(photos) { $1[$0.item].url }
			.take(until: rx.deallocating)
	}
}

extension PhotosViewCell {
	func bind(with photo: Photo) {
		titleLabel.text = photo.title
		let image = URLSession.shared.rx.data(request: URLRequest(url: photo.thumbnailUrl))
			.map { UIImage(data: $0) ?? #imageLiteral(resourceName: "EmptyViewBackground") }
			.catchAndReturn(#imageLiteral(resourceName: "EmptyViewBackground"))
			.share()

		image
			.startWith(#imageLiteral(resourceName: "EmptyViewBackground"))
			.bind(to: imageView.rx.image)
			.disposed(by: disposeBag)

		image
			.map(to: false)
			.startWith(true)
			.distinctUntilChanged()
			.bind(to: activityIndicator.rx.isAnimating)
			.disposed(by: disposeBag)
	}
}
