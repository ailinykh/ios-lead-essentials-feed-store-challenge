//
//  CodableFeedStore.swift
//  FeedStoreChallenge
//
//  Created by Anton Ilinykh on 14.02.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

public class CodableFeedStore: FeedStore {
	private struct Cache: Codable {
		let feed: [CodableFeedImage]
		let timestamp: Date
		
		var toLocal: [LocalFeedImage] {
			feed.map { $0.local }
		}
	}
	
	private struct CodableFeedImage: Codable {
		public let id: UUID
		public let description: String?
		public let location: String?
		public let url: URL
		
		init(_ image: LocalFeedImage) {
			self.id = image.id
			self.description = image.description
			self.location = image.location
			self.url = image.url
		}
		
		var local: LocalFeedImage {
			LocalFeedImage(id: id, description: description, location: location, url: url)
		}
	}
	
	private let storeURL: URL
	private let queue = DispatchQueue(label: "codable-feed-store-cache.queue", qos: .userInitiated)
	
	public init(storeURL: URL) {
		self.storeURL = storeURL
	}
	
	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		let storeURL = self.storeURL
		queue.async {
			guard FileManager.default.fileExists(atPath: storeURL.path) else {
				return completion(nil)
			}
			do {
				try FileManager.default.removeItem(at: storeURL)
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}
	
	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let storeURL = self.storeURL
		queue.async {
			do {
				let encoder = JSONEncoder()
				let cache = Cache(feed: feed.map { CodableFeedImage($0) }, timestamp: timestamp)
				let data = try encoder.encode(cache)
				try data.write(to: storeURL)
			} catch {
				return completion(error)
			}
			completion(nil)
		}
	}
	
	public func retrieve(completion: @escaping RetrievalCompletion) {
		let storeURL = self.storeURL
		queue.async {
			guard let data = try? Data(contentsOf: storeURL) else {
				return completion(.empty)
			}
			
			do {
				let decoder = JSONDecoder()
				let cache = try decoder.decode(Cache.self, from: data)
				completion(.found(feed: cache.toLocal, timestamp: cache.timestamp))
			} catch {
				completion(.failure(error))
			}
		}
	}
}
