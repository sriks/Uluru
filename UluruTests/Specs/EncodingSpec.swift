//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Quick
import Nimble
@testable import Uluru

// Tests default encoding strategies.
class EncodingSpec: QuickSpec {

    func sampleResolvedDefinition(encoding: EncodingStrategy, method: TargetMethod = .GET, headers: [String: String]? = nil) -> ResolvedAPIDefinition {
        return ResolvedAPIDefinition(url: URL(string: "https://example.com")!,
                                     path: "/some-path",
                                     method: method,
                                     encoding: encoding,
                                     headers: headers,
                                     authorizationType: .none)
    }

    override func spec() {

        var requestMapper: ServiceProvider.RequestMapper  { return ServiceProvider.defaultRequestMapper() }

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
                let api = self.sampleResolvedDefinition(encoding: .ignore)
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

            beforeEach {
                CustomEncoder.isInvoked = false
                let api = self.sampleResolvedDefinition(encoding: .jsonBodyUsingCustomEncoder(parameters: postParams, encoder: CustomEncoder()),
                                                        method: .POST)
                urlRequest = try! requestMapper(api).get()
            }

            it("custom encoder is indeed used") {
                let decodedBody = try! JSONDecoder().decode(TestParameters.self, from: urlRequest.httpBody!)
                // Checking if our custom encoder is indeed invoked.
                expect(CustomEncoder.isInvoked).to(beTrue())
            }
            it("body is json encoded") {
                let decodedBody = try! JSONDecoder().decode(TestParameters.self, from: urlRequest.httpBody!)
                expect(decodedBody).to(equal(postParams))
            }

            it("body is nil when no parameters are supplied") {
                let api = self.sampleResolvedDefinition(encoding: .ignore)
                let urlRequest = try! requestMapper(api).get()
                expect(urlRequest.httpBody).to(beNil())
            }

            it("headers includes application/json") {
                let contentTypeHeaders = ["Content-Type": "application/json"]
                expect(urlRequest.allHTTPHeaderFields).to(equal(contentTypeHeaders))
            }

        }

        context("HTTP Methods") {

            func ourMappedUrlRequest(_ method: TargetMethod) -> URLRequest {
                let api = self.sampleResolvedDefinition(encoding: .ignore, method: method)
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

            func ourMappedUrlRequest(_ method: TargetMethod, headers: [String: String]?) -> URLRequest {
                let api = self.sampleResolvedDefinition(encoding: .ignore, method: method, headers: headers)
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

// A fake encoder
class CustomEncoder: JSONEncoder {
    static var isInvoked = false

    override func encode<T>(_ value: T) throws -> Data where T : Encodable {
        CustomEncoder.isInvoked = true
        return try JSONEncoder().encode(value)
    }
}

