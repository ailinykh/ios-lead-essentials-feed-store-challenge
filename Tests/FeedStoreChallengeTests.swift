//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge

class LocalFeedStore: FeedStore {
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
	
	let storeURL: URL
	
	init(storeURL: URL) {
		self.storeURL = storeURL
	}
	
	func deleteCachedFeed(completion: @escaping DeletionCompletion) {
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
	
	func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
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
	
	func retrieve(completion: @escaping RetrievalCompletion) {
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

class FeedStoreChallengeTests: XCTestCase, FeedStoreSpecs {
	
	//  ***********************
	//
	//  Follow the TDD process:
	//
	//  1. Uncomment and run one test at a time (run tests with CMD+U).
	//  2. Do the minimum to make the test pass and commit.
	//  3. Refactor if needed and commit again.
	//
	//  Repeat this process until all tests are passing.
	//
	//  ***********************
	
	override func setUp() {
		super.setUp()
		
		deleteStoreArtifacts()
	}
	
	override func tearDown() {
		super.tearDown()
		
		deleteStoreArtifacts()
	}
	
	func test_retrieve_deliversEmptyOnEmptyCache() {
		let sut = makeSUT()
		
		assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
	}
	
	func test_retrieve_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()
		
		assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
	}
	
	func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
		let sut = makeSUT()
		
		assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
	}
	
	func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
		let sut = makeSUT()
		
		assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
	}
	
	func test_insert_deliversNoErrorOnEmptyCache() {
		let sut = makeSUT()
		
		assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
	}
	
	func test_insert_deliversNoErrorOnNonEmptyCache() {
		let sut = makeSUT()
		
		assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
	}
	
	func test_insert_overridesPreviouslyInsertedCacheValues() {
		let sut = makeSUT()
		
		assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
	}
	
	func test_delete_deliversNoErrorOnEmptyCache() {
		let sut = makeSUT()
		
		assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
	}
	
	func test_delete_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()
		
		assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
	}
	
	func test_delete_deliversNoErrorOnNonEmptyCache() {
		let sut = makeSUT()
		
		assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
	}
	
	func test_delete_emptiesPreviouslyInsertedCache() {
		let sut = makeSUT()
		
		assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
	}
	
	func test_storeSideEffects_runSerially() {
		let sut = makeSUT()
		
		assertThatSideEffectsRunSerially(on: sut)
	}
	
	// - MARK: Helpers
	
	private func makeSUT(url: URL? = nil) -> FeedStore {
		return LocalFeedStore(storeURL: url ?? testSpecificStoreURL())
	}
	
	private func testSpecificStoreURL() -> URL {
		cacheDirectory().appendingPathComponent("\(type(of: self)).cache")
	}
	
	private func cacheDirectory() -> URL {
		FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
	}
	
	private func deleteStoreArtifacts() {
		try? FileManager.default.removeItem(at: testSpecificStoreURL())
	}
}

//  ***********************
//
//  Uncomment the following tests if your implementation has failable operations.
//
//  Otherwise, delete the commented out code!
//
//  ***********************

extension FeedStoreChallengeTests: FailableRetrieveFeedStoreSpecs {

	func test_retrieve_deliversFailureOnRetrievalError() {
		let sut = makeSUT()
		
		try! Data("Invalid Data".utf8).write(to: testSpecificStoreURL())
		
		assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
	}

	func test_retrieve_hasNoSideEffectsOnFailure() {
		let sut = makeSUT()
		
		try! Data("Invalid Data".utf8).write(to: testSpecificStoreURL())
		
		assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
	}

}

extension FeedStoreChallengeTests: FailableInsertFeedStoreSpecs {

	func test_insert_deliversErrorOnInsertionError() {
		let invalidStoreURL = URL(string: "invalid-url://nothing")!
		let sut = makeSUT(url: invalidStoreURL)

		assertThatInsertDeliversErrorOnInsertionError(on: sut)
	}

	func test_insert_hasNoSideEffectsOnInsertionError() {
		let invalidStoreURL = URL(string: "invalid-url://nothing")!
		let sut = makeSUT(url: invalidStoreURL)

		assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
	}

}

extension FeedStoreChallengeTests: FailableDeleteFeedStoreSpecs {

	func test_delete_deliversErrorOnDeletionError() {
		let nonDeletePermissionURL = cacheDirectory()
		let sut = makeSUT(url: nonDeletePermissionURL)

		assertThatDeleteDeliversErrorOnDeletionError(on: sut)
	}

	func test_delete_hasNoSideEffectsOnDeletionError() {
		let nonDeletePermissionURL = cacheDirectory()
		let sut = makeSUT(url: nonDeletePermissionURL)

		assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
	}

}
