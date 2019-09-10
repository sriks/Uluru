//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

/// Represents a success response hot and fresh.
public struct DataSuccessResponse {
    let data: Data
    let urlResponse: HTTPURLResponse
}

/// Represents a network error response hot and fresh.
public struct DataErrorResponse: Error {
    let error: Error
    let data: Data?
    let urlResponse: HTTPURLResponse?
}

// Raw Data Requests
public typealias DataResult = Result<DataSuccessResponse, DataErrorResponse>
public typealias DataRequestCompletion = (_ completion: DataResult) -> Void

// JSON requests
public typealias APIRequestCompletion<T: Decodable> = (_ result: Result<T, ServiceError>) -> Void

public protocol Service {
    associatedtype API: APIDefinition

    func requestData(_ api: API,
                     completion: @escaping DataRequestCompletion) -> ServiceCancellable

    func request<T: Decodable>(_ api: API,
                               expecting: T.Type,
                               completion: @escaping APIRequestCompletion<T>) -> ServiceCancellable

}


