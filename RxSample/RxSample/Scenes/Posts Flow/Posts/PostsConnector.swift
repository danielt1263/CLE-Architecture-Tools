//
//  PostsConnector.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/13/20.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import RxCocoa
import RxSwift
import UIKit

extension UITableViewController {
	func connectPosts() -> Observable<Post> {
		tableView.refreshControl = UIRefreshControl()
		tableView.dataSource = nil
		tableView.delegate = nil

		let postsResult = PostsLogic.getPosts(
			trigger: tableView.refreshControl!.rx.controlEvent(.valueChanged).asObservable(),
			user: user
		)
		.flatMapLatest {
			api.response(.getPosts(id: $0))
		}
		.share(replay: 1)

		_ = Observable.merge(
			tableView.refreshControl!.rx.controlEvent(.valueChanged).map(to: true),
			postsResult.map(to: false)
		)
		.take(until: rx.deallocating)
		.bind(to: tableView.refreshControl!.rx.isRefreshing)

		_ = Observable.merge(
			postsResult,
			user.filter { $0 == nil }.map(to: [Post]())
		)
		.take(until: rx.deallocating)
		.bind(to: tableView.rx.items) { tableView, row, item in
			(tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "Cell"))
				.setup {
					$0.textLabel!.text = item.title
					$0.detailTextLabel!.text = item.body
				}
		}

		let action = tableView.rx.modelSelected(Post.self)
			.asObservable()
			.take(until: rx.deallocating)

		return action
	}
}

extension Reactive where Base: UIRefreshControl {
	var isRefreshing: Binder<Bool> {
		Binder(base) { control, isRefreshing in
			if isRefreshing {
				base.beginRefreshing()
			}
			else {
				base.endRefreshing()
			}
		}
	}
}
