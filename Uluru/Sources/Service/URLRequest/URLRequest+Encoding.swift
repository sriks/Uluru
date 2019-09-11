//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

enum EncodingError: Error {
    case invalidResolvedUrl
    case failedToConstructUrlWithQueryParameters
    case jsonSerialization(error: Error)
}

extension URLRequest {
    @discardableResult
    mutating func encoded(_ encodingTask: EncodingStrategy) throws -> URLRequest {
        guard let ourUrl = url else { return self }
        switch encodingTask {
        case .ignore:
            return self

        case .queryParameters(let parameters):
            guard var comps = URLComponents(string: ourUrl.absoluteString) else {
                throw EncodingError.invalidResolvedUrl
            }
            comps.queryItems = try parameters.jsonObject().map { return URLQueryItem(name: $0.key, value: "\($0.value)")}
            guard let urlWithQueryParams = comps.url else {
                throw EncodingError.failedToConstructUrlWithQueryParameters
            }
            url = urlWithQueryParams
            return self

        case let .jsonBodyUsingCustomEncoder(parameters, encoder):
            return try applyingBody(parameters, encoder: encoder)

        case let .jsonBody(parameters):
            return try applyingBody(parameters, encoder: JSONEncoder())
        }
    }

    @discardableResult
    mutating func applyingBody(_ parameters: JSONRepresentable, encoder: JSONEncoder) throws -> URLRequest {
        do {
            let data = try parameters.jsonData(using: encoder)
            httpBody = data
            return self
        } catch {
            #if DEBUG
            print("Setting HTTP boday failed for \(self) with JSONSerialization error \(error)")
            #endif
            throw EncodingError.jsonSerialization(error: error)
        }
    }
}

extension EncodingStrategy {
    var expectsApplicationJSONHeader: Bool {
        switch self {
        case .ignore, .queryParameters:
            return false
        case .jsonBody, .jsonBodyUsingCustomEncoder:
            return true
        }
    }
}
