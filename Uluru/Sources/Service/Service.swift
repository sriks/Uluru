//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

/// Represents a data response.
public struct DataResponse {
    let data: Data
    let request: URLRequest
    let urlResponse: HTTPURLResponse?
}

// Raw Data Requests
public typealias DataResult = Result<DataResponse, ServiceError>
public typealias DataRequestCompletion = (_ completion: DataResult) -> Void

/// Represents a parsed data request.
public struct ParsedDataResponse<T: Decodable> {
    let parsed: T
    let underlying: DataResponse
}

// Parsed requests
public typealias ParsedDataResponseResult<T: Decodable> = Result<ParsedDataResponse<T>, ServiceError>
public typealias APIRequestCompletion<T: Decodable> = (_ result: Result<ParsedDataResponse<T>, ServiceError>) -> Void

public protocol Service {
    associatedtype API: APIDefinition

    func requestData(_ api: API,
                     completion: @escaping DataRequestCompletion) -> ServiceCancellable

    func request<T: Decodable>(_ api: API,
                               expecting: T.Type,
                               completion: @escaping APIRequestCompletion<T>) -> ServiceCancellable

}


