//
//  TodosConnector.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 11/14/20.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import Cause_Logic_Effect
import RxCocoa
import RxSwift
import UIKit

extension UITableViewController {
	func connectTodos() {
		tableView.refreshControl = UIRefreshControl()
		tableView.dataSource = nil
		tableView.delegate = nil
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

		let todosResult = tableView.refreshControl!.rx.controlEvent(.valueChanged).startWith(())
			.flatMapLatest { api.response(.getTodos) }
			.share(replay: 1)

		_ = Observable.merge(
			tableView.refreshControl!.rx.controlEvent(.valueChanged).map(to: true),
			todosResult.map(to: false)
		)
		.take(until: rx.deallocating)
		.bind(to: tableView.refreshControl!.rx.isRefreshing)

		_ = todosResult
			.take(until: rx.deallocating)
			.bind(to: tableView.rx.items) { tableView, row, element in
				let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: IndexPath(row: row, section: 0))
				cell.textLabel!.text = element.title
				return cell
			}
	}
}
