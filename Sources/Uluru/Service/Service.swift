//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

/// Represents a data response from a HTTP API call.
public struct DataResponse {
    public let data: Data
    public let request: URLRequest
    public let urlResponse: HTTPURLResponse?

    public init(data: Data, request: URLRequest, urlResponse: HTTPURLResponse?) {
        self.data = data
        self.request = request
        self.urlResponse = urlResponse
    }
}

// Raw Data Requests
public typealias DataResult = Result<DataResponse, ServiceError>
public typealias DataRequestCompletion = (_ completion: DataResult) -> Void

/// Represents a parsed data request
/// * Use `parsed` to get the parsed model.
public struct ParsedDataResponse<T: Decodable> {
    public let parsed: T
    public let dataResponse: DataResponse
}

// Parsed requests
public typealias ParsedDataResponseResult<T: Decodable> = Result<ParsedDataResponse<T>, ServiceError>
public typealias APIRequestCompletion<T: Decodable> = (_ result: Result<ParsedDataResponse<T>, ServiceError>) -> Void

/// Ability to make a request with an APIDefinition. This can be used for reactive extensions.
public protocol Service {
    associatedtype API: APIDefinition

    /// Makes an API request with supplied APIDefinition
    /// * Dont have to keep a strong reference of the returned cancellable unless you want to cancel the request.
    /// - Parameters:
    ///   - api: The APIDefinition which provides the **what** part of an endpoint.
    ///   - expecting: The expected `Swift.Decodable` model.
    @discardableResult
    func request<T: Decodable>(_ api: API,
                               expecting: T.Type,
                               completion: @escaping APIRequestCompletion<T>) -> ServiceCancellable
}


