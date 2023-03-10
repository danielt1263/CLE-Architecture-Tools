//
//  AlbumsConnector.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/13/20.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import Cause_Logic_Effect
import UIKit
import RxSwift
import RxCocoa

extension UITableViewController {
	func connectAlbums() -> Observable<Album> {
		tableView.refreshControl = UIRefreshControl()
		tableView.dataSource = nil
		tableView.delegate = nil

		let albumsResult = tableView.refreshControl!.rx.controlEvent(.valueChanged).startWith(())
			.flatMapLatest { api.response(.getAlbums) }
			.share(replay: 1)

		_ = Observable.merge(
			tableView.refreshControl!.rx.controlEvent(.valueChanged).map(to: true),
			albumsResult.map(to: false)
		)
		.take(until: rx.deallocating)
		.bind(to: tableView.refreshControl!.rx.isRefreshing)

		_ = albumsResult
			.take(until: rx.deallocating)
			.bind(to: tableView.rx.items) { tableView, row, element in
				let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
				cell.textLabel!.text = element.title
				return cell
			}

		return tableView.rx.itemSelected
			.withLatestFrom(albumsResult) { $1[$0.row] }
			.take(until: rx.deallocating)
	}
}
