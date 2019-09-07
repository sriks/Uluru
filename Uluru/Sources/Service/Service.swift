//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

/// Represents a success response hot and fresh right way from the network.
public struct DataSuccessResponse {
    let data: Data
    let urlResponse: HTTPURLResponse
}

/// Represents a network error response hot and fresh right way from the network.
public struct DataErrorResponse: Error {
    let error: Error
    let data: Data?
    let urlResponse: HTTPURLResponse?
}

// Raw Data Requests
public typealias DataResult = Result<DataSuccessResponse, DataErrorResponse>
public typealias DataRequestCompletion = (_ completion: DataResult) -> Void

// JSON requests
public typealias APIResult<T: Decodable> = Result<T, Error>
public typealias APIRequestCompletion<T: Decodable> = (_ completion: APIResult<T>) -> Void

public protocol Service {
    associatedtype API: APIDefinition

    func requestData(_ api: API,
                     completion: @escaping DataRequestCompletion) -> ServiceCancellable

    func request<T: Decodable>(_ api: API,
                               completion: @escaping APIRequestCompletion<T>) -> ServiceCancellable
}


