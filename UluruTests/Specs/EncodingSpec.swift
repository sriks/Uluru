//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Quick
import Nimble
@testable import Uluru

// Tests default encoding strategies.
class EncodingSpec: QuickSpec {

    func sampleResolvedDefinition(encoding: EncodingStrategy, method: HTTPMethod = .GET, headers: [String: String]? = nil) -> APITarget {
        return APITarget(url: URL(string: "https://example.com")!,
                         path: "/some-path",
                         method: method,
                         encoding: encoding,
                         headers: headers)
    }

    override func spec() {

        var requestMapper: ServiceRequester<PostmanEcho>.RequestMapper  { return ServiceRequester<PostmanEcho>.defaultRequestMapper() }

        context("when encoding strategy is .queryParameters") {
            
            let queryParams = TestParameters.make()

            it("request.url includes query params") {
                let urlRequest = try! requestMapper(self.sampleResolvedDefinition(encoding: .queryParameters(parameters: queryParams))).get()
                // Reconstruct url and check if all params are indeed matching.
                let comps = URLComponents(string: urlRequest.url!.absoluteString)!
                expect(comps.queryItems).notTo(beEmpty())
                expect(comps.queryItems!.count).to(equal(try! queryParams.jsonObject().count))
                comps.queryItems!.forEach{ anItem in
                    let expectedValue = try! queryParams.jsonObject()[anItem.name]!
                    expect(anItem.value).to(equal("\(expectedValue)"))
                }
            }

            it("url is untouched when query parameters are not supplied") {
                let urlRequest = try! requestMapper(self.sampleResolvedDefinition(encoding: .queryParameters(parameters: EmptyParameters()))).get()
                // Reconstruct url and check if all params are indeed matching.
                let comps = URLComponents(string: urlRequest.url!.absoluteString)!
                expect(comps.queryItems).to(beEmpty())
            }

         }

        context("when encoding strategy is .jsonBody") {

            let postParams = TestParameters.make()
            var urlRequest: URLRequest!

            beforeEach {
                let api = self.sampleResolvedDefinition(encoding: .jsonBody(parameters: postParams), method: .POST)
                urlRequest = try! requestMapper(api).get()
            }

            it("body is json encoded") {
                let decodedBody = try! JSONDecoder().decode(TestParameters.self, from: urlRequest.httpBody!)
                expect(decodedBody).to(equal(postParams))
            }

            it("body is nil when no parameters are supplied") {
                let api = self.sampleResolvedDefinition(encoding: .dontEncode)
                let urlRequest = try! requestMapper(api).get()
                expect(urlRequest.httpBody).to(beNil())
            }

            it("headers includes application/json") {
                let contentTypeHeaders = ["Content-Type": "application/json"]
                expect(urlRequest.allHTTPHeaderFields).to(equal(contentTypeHeaders))
            }
        }

        context("when encoding strategy is .jsonBodyUsingCustomEncoder") {

            let postParams = TestParameters.make()
            var urlRequest: URLRequest!
            var customEncoder: CustomEncoder!

            beforeEach {
                customEncoder = CustomEncoder()
                let api = self.sampleResolvedDefinition(encoding: .jsonBodyUsingCustomEncoder(parameters: postParams, encoder: customEncoder),
                                                        method: .POST)
                urlRequest = try! requestMapper(api).get()
            }

            it("custom encoder is indeed used") {
                let decodedBody = try! JSONDecoder().decode(TestParameters.self, from: urlRequest.httpBody!)
                // Checking if our custom encoder is indeed invoked.
                expect(customEncoder.isInvoked).to(beTrue())
            }
            it("body is json encoded") {
                let decodedBody = try! JSONDecoder().decode(TestParameters.self, from: urlRequest.httpBody!)
                expect(decodedBody).to(equal(postParams))
            }

            it("body is nil when no parameters are supplied") {
                let api = self.sampleResolvedDefinition(encoding: .dontEncode)
                let urlRequest = try! requestMapper(api).get()
                expect(urlRequest.httpBody).to(beNil())
            }

            it("headers includes application/json") {
                let contentTypeHeaders = ["Content-Type": "application/json"]
                expect(urlRequest.allHTTPHeaderFields).to(equal(contentTypeHeaders))
            }

        }

        context("HTTP Methods") {

            func ourMappedUrlRequest(_ method: HTTPMethod) -> URLRequest {
                let api = self.sampleResolvedDefinition(encoding: .dontEncode, method: method)
                return try! requestMapper(api).get()
            }

            it("request should have GET as httpMethod") {
                let urlRequest = ourMappedUrlRequest(.GET)
                expect(urlRequest.httpMethod).to(equal("GET"))
            }

            it("request should have POST as httpMethod") {
                let urlRequest = ourMappedUrlRequest(.POST)
                expect(urlRequest.httpMethod).to(equal("POST"))
            }

            it("request should have PUT as httpMethod") {
                let urlRequest = ourMappedUrlRequest(.PUT)
                expect(urlRequest.httpMethod).to(equal("PUT"))
            }

            it("request should have DELETE as httpMethod") {
                let urlRequest = ourMappedUrlRequest(.DELETE)
                expect(urlRequest.httpMethod).to(equal("DELETE"))
            }

        }

        context("HTTP Headers") {

            func ourMappedUrlRequest(_ method: HTTPMethod, headers: [String: String]?) -> URLRequest {
                let api = self.sampleResolvedDefinition(encoding: .dontEncode, method: method, headers: headers)
                return try! requestMapper(api).get()
            }

            it("should contain headers supplied in definition") {
                let headers = ["foo": "bar"]
                let urlRequest = ourMappedUrlRequest(.GET, headers: headers)
                expect(urlRequest.allHTTPHeaderFields).to(equal(headers))
            }
        }
    }
}

struct CommentById: Encodable, JSONRepresentable {
    let postId: Int
}

enum SampleAPI {
    case simpleGET
    case getWithParams(postId: CommentById)
}

extension SampleAPI: APIDefinition {
    var baseURL: URL {
        return URL(string: "https://jsonplaceholder.typicode.com")!
    }

    var path: String {
        switch self {
        case .simpleGET:
            return "/posts/1"

        case .getWithParams:
            return "/comments"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .simpleGET, .getWithParams:
            return .GET


        }
    }

    var encoding: EncodingStrategy {
        switch self {
        case .simpleGET:
            return .dontEncode

        case let .getWithParams(postId):
            return .queryParameters(parameters: postId)
        }
    }

    var headers: [String : String]? {
        return nil
    }

    var authorizationType: AuthenticationStrategy {
        return .none
    }

}

struct EmptyParameters: Codable, Equatable, JSONRepresentable {}

struct TestParameters: Codable, Equatable, JSONRepresentable {
    let state: String
    let city: String
    let postcode: Int
    let isSunny: Bool

    static func make() -> TestParameters {
        return TestParameters(state: "New South Wales", city: "Sydney", postcode: 2000, isSunny: true)
    }
}
