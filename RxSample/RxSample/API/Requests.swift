//
//  Requests.swift
//  RxMyCoordinator
//
//  Created by Daniel Tartaglia on 2/15/19.
//

import Cause_Logic_Effect
import Foundation

let baseURLString = "https://jsonplaceholder.typicode.com"

extension Endpoint where Response == [Post] {
	static func getPosts(id: User.ID) -> Endpoint {
		var components = URLComponents(string: baseURLString)!
		components.path = "/posts"
		components.queryItems = [URLQueryItem(name: "userId", value: "\(id.rawValue)")]
		return Endpoint(request: URLRequest(url: components.url!), decoder: jsonDecoder)
	}
}

extension Endpoint where Response == [Album] {
	static var getAlbums: Endpoint {
		var components = URLComponents(string: baseURLString)!
		components.path = "/albums"
		return Endpoint(request: URLRequest(url: components.url!), decoder: jsonDecoder)
	}
}

extension Endpoint where Response == [Photo] {
	static func getPhotos(id: Album.ID) -> Endpoint {
		var components = URLComponents(string: baseURLString)!
		components.path = "/photos"
		components.queryItems = [URLQueryItem(name: "albumId", value: "\(id.rawValue)")]
		return Endpoint(request: URLRequest(url: components.url!), decoder: jsonDecoder)
	}
}

extension Endpoint where Response == [Todo] {
	static var getTodos: Endpoint {
		var components = URLComponents(string: baseURLString)!
		components.path = "/todos"
		return Endpoint(request: URLRequest(url: components.url!), decoder: jsonDecoder)
	}
}

extension Endpoint where Response == User {
	static func getUser(id: Int) -> Endpoint {
		var components = URLComponents(string: baseURLString)!
		components.path = "/users/\(id)"
		return Endpoint(
			request: URLRequest(url: components.url!),
			response: {
				// force a fake error
				let loginResult = arc4random() % 5 == 0 ? false : true
				guard loginResult == true else { throw AuthenticationError.invalidCredentials }
				return try jsonDecoder.decode(User.self, from: $0)
			}
		)
	}
}

extension URLRequest {
	static func getPhotos(forAlbumId id: Int) -> URLRequest {
		var components = URLComponents(string: baseURLString)!
		components.path = "/photos"
		components.queryItems = [URLQueryItem(name: "albumId", value: "\(id)")]
		return URLRequest(url: components.url!)
	}
}

private let jsonDecoder: JSONDecoder = {
	let result = JSONDecoder()
	result.keyDecodingStrategy = .convertFromSnakeCase
	return result
}()
