//
//  TabConnector.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 11/14/20.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift
import RxCocoa

extension UITabBarController {

	func connect() {
		let posts = UINavigationController().configure { $0.connectPosts() }
		posts.tabBarItem = UITabBarItem(title: "Posts", image: #imageLiteral(resourceName: "PostsTabIcon"), tag: 0)

		let albums = UINavigationController().configure { $0.connectAlbums() }
		albums.tabBarItem = UITabBarItem(title: "Albums", image: #imageLiteral(resourceName: "AlbumsTabIcon"), tag: 1)

		let todos = UITableViewController().configure { $0.connectTodos() }
		todos.tabBarItem = UITabBarItem(title: "Todos", image: #imageLiteral(resourceName: "TodosTabIcon"), tag: 2)

		let profile = UINavigationController().configure { $0.connectProfile() }
		profile.tabBarItem = UITabBarItem(title: "Profile", image: #imageLiteral(resourceName: "ProfileTabIcon"), tag: 3)

		// set back to the first tab when the user logs out
		_ = user
			.filter { $0 == nil }
			.map(to: ())
			.bind { [unowned self] in
				self.selectedIndex = 0
			}

		viewControllers = [
			posts,
			albums,
			UINavigationController(rootViewController: todos),
			profile
		]
	}
}
