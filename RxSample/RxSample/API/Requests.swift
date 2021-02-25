//
//  Requests.swift
//  RxMyCoordinator
//
//  Created by Daniel Tartaglia on 2/15/19.
//

import Foundation

let baseURLString = "https://jsonplaceholder.typicode.com"

extension Endpoint where T == [Post] {
	static func getPosts(id: User.ID) -> Endpoint {
		var components = URLComponents(string: baseURLString)!
		components.path = "/posts"
		components.queryItems = [URLQueryItem(name: "userId", value: "\(id.rawValue)")]
		return Endpoint(request: URLRequest(url: components.url!))
	}
}

extension Endpoint where T == [Album] {
	static var getAlbums: Endpoint {
		var components = URLComponents(string: baseURLString)!
		components.path = "/albums"
		return Endpoint(request: URLRequest(url: components.url!))
	}
}

extension Endpoint where T == [Photo] {
	static func getPhotos(id: Album.ID) -> Endpoint {
		var components = URLComponents(string: baseURLString)!
		components.path = "/photos"
		components.queryItems = [URLQueryItem(name: "albumId", value: "\(id.rawValue)")]
		return Endpoint(request: URLRequest(url: components.url!))
	}
}

extension Endpoint where T == [Todo] {
	static var getTodos: Endpoint {
		var components = URLComponents(string: baseURLString)!
		components.path = "/todos"
		return Endpoint(request: URLRequest(url: components.url!))
	}
}

extension Endpoint where T == User {
	static func getUser(id: Int) -> Endpoint {
		var components = URLComponents(string: baseURLString)!
		components.path = "/users/\(id)"
		return Endpoint(
			request: URLRequest(url: components.url!),
			response: {
				// just a mock
				let loginResult = arc4random() % 5 == 0 ? false : true
				guard loginResult == true else { throw AuthenticationError.invalidCredentials }
				return try jsonDecoder.decode(T.self, from: $0)
			})
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
