//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
@testable import Uluru

enum PostmanEcho {
    case justGet
    case getWithParams(params: JSONRepresentable)
    case postWithBody(body: JSONRepresentable)
    case postBodyWithCustomEncoder(body: JSONRepresentable)
    case postWithoutBody
    case justGetWithPlaceholderData
    // returns supplied headers in response.
    case echoBearerAuth
    case echoCustomHeaderAuth(headerName: String)
}

extension PostmanEcho: APIDefinition, AccessAuthorizable {

    var baseURL: URL {
        return URL(string: "https://postman-echo.com")!
    }

    var path: String {
        switch self {
        case .getWithParams, .justGet, .justGetWithPlaceholderData:
            return "/get"

        case .echoBearerAuth, .echoCustomHeaderAuth:
            return "/headers"

        case .postWithBody, .postBodyWithCustomEncoder, .postWithoutBody:
            return "/post"
        }
    }

    var method: TargetMethod {
        switch self {
        case .getWithParams, .justGet, .justGetWithPlaceholderData, .echoBearerAuth, .echoCustomHeaderAuth:
            return .GET

        case .postWithBody, .postBodyWithCustomEncoder, .postWithoutBody:
            return .POST
        }
    }

    var encoding: EncodingStrategy {
        switch self {
        case .justGet, .justGetWithPlaceholderData, .echoBearerAuth, .echoCustomHeaderAuth:
            return .ignore
            
        case let .getWithParams(params):
            return .queryParameters(parameters: params)

        case .postWithBody(let body):
            return .jsonBody(parameters: body)

        case .postBodyWithCustomEncoder(let body):
            return .jsonBodyUsingCustomEncoder(parameters: body, encoder: CustomEncoder())

        case .postWithoutBody:
            return .ignore
        }
    }

    var headers: [String: String]? {
        return nil
    }

    var placeholderData: Data? {
        switch self {
        case .justGetWithPlaceholderData:
            return try! JSONEncoder().encode(MockPlaceholder())
        default:
            return nil
        }
    }

    var authenticationStrategy: AuthenticationStrategy {
        switch self {
        case .echoBearerAuth:
            return .bearer
        case .echoCustomHeaderAuth(let headerName):
            return .customHeaderField(headerName)
        default:
            return .none
        }
    }
}

struct MockPlaceholder: Codable, Equatable {
    let name = "This is placeholder data."
}

struct EmptyDecodableModel: Decodable {}

/// Contains reponse which echoes supplied headers.
/// https://docs.postman-echo.com/?version=latest#da16c006-6293-c1fe-ea42-e9ba8a5e68b1
struct EchoHeaders: Codable, Equatable, JSONRepresentable {
    let headers: [String: String]
}
