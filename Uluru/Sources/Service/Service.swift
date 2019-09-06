//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

/// Represents a success response hot and fresh right way from the network.
public struct RawSuccessResponse {
    let data: Data
    let urlResponse: HTTPURLResponse
}

/// Represents a network error response hot and fresh right way from the network.
public struct RawErrorResponse: Error {
    let error: Error
    let data: Data?
    let urlResponse: HTTPURLResponse?
}

// Raw Data Requests
public typealias ResponseResult = Result<RawSuccessResponse, RawErrorResponse>
public typealias ResponseCompletion = (_ completion: ResponseResult) -> Void

// JSON requests
public typealias APIResult<T: Decodable> = Result<T, Error>
public typealias APIRequestCompletion<T: Decodable> = (_ completion: APIResult<T>) -> Void

public protocol Service {
    func perform(_ apiDefinition: APIDefinition,
                 completion: @escaping ResponseCompletion) -> ServiceCancellable

    func request<T: Decodable>(_ apiDefinition: APIDefinition,
                               completion: @escaping APIRequestCompletion<T>) -> ServiceCancellable
}


