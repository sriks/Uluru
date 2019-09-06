//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
@testable import Uluru

enum TestAPIDefinition {
    case justGet
    case getWithParams(params: JSONRepresentable)
    case postWithBody(body: JSONRepresentable)
    case postBodyWithCustomEncoder(body: JSONRepresentable)
    case postWithoutBody
}

extension TestAPIDefinition: APIDefinition {
    var baseURL: URL {
        return URL(string: "https://postman-echo.com")!
    }

    var path: String {
        switch self {
        case .getWithParams, .justGet:
            return "/get"

        case .postWithBody, .postBodyWithCustomEncoder, .postWithoutBody:
            return "/post"
        }
    }

    var method: TargetMethod {
        switch self {
        case .getWithParams, .justGet:
            return .GET

        case .postWithBody, .postBodyWithCustomEncoder, .postWithoutBody:
            return .POST
        }
    }

    var encoding: EncodingStrategy {
        switch self {
        case .justGet:
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

    var authorizationType: TypeOfAuthorization {
        return .none
    }
}

struct TestDecodableModel: Decodable {}
