//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

/// A conformance to represent an error response. For example API returned an error response stating missing mandatory fields.
public typealias ErrorResponse = Error & Decodable

// MARK: ServiceError
/// Service Error. Collection of all possible errors that can result when performing a request.
public enum ServiceError: Error {

    // The url cannot be resolved when mapping to an URLRequest.
    case invalidResolvedUrl(URL)

    // Failed to encode url parameters. The URL and JSONRepresentable parameters
    case parameterEncoding(URL, JSONRepresentable)

    // Failed to apply supplied body. The JSONRepresentable body, the encoder and underlying error.
    case applyingBody(JSONRepresentable, JSONEncoder, Error)

    // Failed with unknown error tring to map APITarget to an URLRequest
    case requestMapping(APITarget)

    // Decoding failed
    case parsing(Error, DataResponse)

    // An underyling error like network error. The error and any response which resulted in this error.
    case underlying(Error, DataResponse?)

    // An error response from API. The request went through but API returned an error, for example missing required fields etc.
    // The data response, parsed ErrorResponse as per your API contract.
    case response(DataResponse, ErrorResponse)
}

extension ServiceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidResolvedUrl:
            return  "The resolved url is invalid."
        case .parameterEncoding:
            return "Failed to perform parameter encoding"
        case .applyingBody:
            return "Failed to apply request body"
        case .requestMapping:
            return "Failed to map to an URLRequest"
        case .parsing:
            return "Failed parsing"
        case .underlying(let error, _):
            return error.localizedDescription
        case .response(_, _):
            return "Error response"
        }
    }
}

// MARK: ParsingError
/// A parsing error
public enum ParsingError: Error {
    // Parsing failed with error.
    case parsing(Error)

    // Parsed successfully and got an error response.
    case response(ErrorResponse)
}

