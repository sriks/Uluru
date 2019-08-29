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

public typealias ResponseResult = Result<RawSuccessResponse, RawErrorResponse>
public typealias ResponseCompletion = (_ completion: ResponseResult) -> Void

public protocol Service {
    func request(_ apiDefinition: APIDefinition,
                 completion: @escaping ResponseCompletion) -> ServiceCancellable
}

public typealias APIResult<T: Decodable> = Result<T, Error>
public typealias APIRequestCompletion<T: Decodable> = (_ completion: APIResult<T>) -> Void

// API Service - performs JSON API requests
public protocol APIService {
    func request<T: Decodable>(_ apiDefinition: APIDefinition, completion: @escaping APIRequestCompletion<T>) -> ServiceCancellable
}
