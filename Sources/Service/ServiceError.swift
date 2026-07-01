import Foundation

/// A conformance to represent an error response. For example API returned an error response stating missing mandatory fields.
/// * Conform to this to represent the exact API error.
/// * For example `struct MyAPIErrorResponse: APIErrorResponse {}`
/// * The `ResponseParser` implementation is responsible to create the exact error.
/// * Ensure to conform to `LocalizedError` and provide `errorDescription` so that localized error description is used when `error.localizedDescription` is invoked.
public typealias APIErrorResponse = Error & LocalizedError

// MARK: ServiceError
/// Service Error. Collection of all possible errors that can result when performing a request.
public enum ServiceError: Error {

    /// The url cannot be resolved when mapping to an URLRequest.
    case invalidResolvedUrl(URL)

    /// Target resolver failed which resolves an APIDefintion to an APITarget with fully formed URL
    /// A resolver is injected into Uluru so the implementation can provide the exact error information.
    /// The underlying error reason.
    case targetResolverFailed(String)

    /// Failed to encode url parameters. The URL and JSONRepresentable parameters
    case parameterEncoding(URL, JSONRepresentable)

    /// Failed to apply supplied body. The JSONRepresentable body, the encoder and underlying error.
    case applyingBody(JSONRepresentable, JSONEncoder, Error)

    /// Failed with unknown error tring to map APITarget to an URLRequest
    case requestMapping(APITarget)

    /// Parsing failed. The parsing error and the data response used for parsing.
    case parsing(Error, DataResponse)

    /// An underyling error like network error. The error and any response which resulted in this error.
    /// This is **not** an API error which is represented as `apiError`.
    case underlying(Error, DataResponse?)

    /// An error response from API. The request went through but API returned an error response, for example missing required fields etc.
    ///
    /// The parsed APIErrorResponse as per your API contract and underlying data response.
    /// * The supplied `ResponseParser` is responsible to create the exact type of `ErrorResponse`
    /// * `APIErrorResponse` can be casted to the actual error response as per your API contract.
    case apiError(APIErrorResponse, DataResponse)
}

extension ServiceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidResolvedUrl:
            return  "The resolved url is invalid."
        case .targetResolverFailed:
            return "Unable to resolve into an URL."
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
        case .apiError(let error, _):
            return error.localizedDescription
        }
    }
}

// MARK: ParsingError
/// A parsing error
public enum ParsingError: Error {
    // Parsing failed with error.
    case parsing(Error)

    // Parsed successfully but got an error response from the response JSON.
    case response(APIErrorResponse)
}

