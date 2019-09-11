//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Quick
import Nimble
@testable import Uluru

class ServiceProvderSpec: QuickSpec {
    override func spec() {
        TestHelper.markWaitExpecationAsAPIRequest()

        // MARK: Custom JSONDecoder
        context("Custom JSONDecoder") {
            var service: ServiceProvider<PostmanEcho>!
            beforeEach {
                CustomParser.isInvoked = false
                service = ServiceProvider(parser: CustomParser.self)
            }

            it("uses the provided json decoder") {
                waitUntil { done in
                    let _ = service.request(.justGet, expecting: EmptyDecodableModel.self, completion: { (result) in
                        done()
                    })
                }

                expect(CustomParser.isInvoked).to( beTrue() )
            }
        }

        // MARK: Placeholder data
        context("Placeholder data") {
            var service: ServiceProvider<PostmanEcho>!

            beforeEach {
                service = ServiceProvider()
            }

            it("should return placeholder data when provided") {
                var decoded: MockPlaceholder!
                waitUntil { done in
                    let _  = service.request(.justGetWithPlaceholderData, expecting: MockPlaceholder.self) { result in
                        decoded = try! result.get()
                        done()
                    }
                }

                expect(decoded).to( equal(MockPlaceholder()) )
            }

            it("statusCode of placeholder data response is 200") {
                var dataSuccessResponse: DataSuccessResponse!
                waitUntil { done in
                    let _ = service.requestData(.justGetWithPlaceholderData) { result in
                        dataSuccessResponse = try! result.get()
                        done()
                    }
                }

                expect(dataSuccessResponse.urlResponse.statusCode).to( equal(200) )
            }
        }

        // MARK: Stub Strategies
        context("Stub Strategies") {
            var service: ServiceProvider<PostmanEcho>!

            it("should match with provided stub response") {
                struct StubSuccessResponse: Codable, Equatable, JSONRepresentable {
                    let animal = "Godzilla"
                }
                service = ServiceProvider(stubStrategy: .stub(delay: 0, response: { (target) -> StubResponse in
                    let urlResponse = HTTPURLResponse(url: target.url, statusCode: 200, httpVersion: nil, headerFields: nil)
                    return .network(response: urlResponse!, data: try! StubSuccessResponse().jsonData())
                }))

                waitUntil { done in
                    let _ = service.request(.justGet, expecting: StubSuccessResponse.self, completion: { (result) in
                        expect(try! result.get()).to( equal(StubSuccessResponse()) )
                        done()
                    })
                }
            }

            it("should error") {
                let stubedError = NSError(domain: "Godzilla Error", code: 8086, userInfo: nil)
                let stubStrategy: StubStrategy = .stub(delay: 0, response: { (target) -> StubResponse in
                    return .error(error: stubedError)
                })
                service = ServiceProvider(stubStrategy: stubStrategy)
                var expectedError: NSError?
                waitUntil { done in
                    let _ = service.request(.justGet, expecting: EmptyDecodableModel.self, completion: { (result) in
                        if case .failure(let error) = result, case .requestFailed(let networkError) = error {
                            expectedError = networkError.error as NSError
                        }
                        done()
                    })
                }

                expect(stubedError).to( equal(expectedError) )
            }

            it("should invoke response provider and make a real network request when using .continueCourse") {
                var isStubProviderInvoked: Bool = false
                let stubStrategy: StubStrategy = .stub(delay: 0, response: { (target) -> StubResponse in
                    isStubProviderInvoked = true
                    return .continueCourse
                })

                service = ServiceProvider(stubStrategy: stubStrategy)
                var model: EmptyDecodableModel?
                waitUntil { done in
                    let _ = service.request(.justGet, expecting: EmptyDecodableModel.self, completion: { (result) in
                        model = try! result.get()
                        done()
                    })
                }

                expect(isStubProviderInvoked).to( beTrue() )
                expect(model).notTo( beNil() )
            }

            it("should make real network call when strategy is .dontStub") {
                service = ServiceProvider(stubStrategy: .dontStub)
                var model: EmptyDecodableModel?
                waitUntil { done in
                    let _ = service.request(.justGet, expecting: EmptyDecodableModel.self, completion: { (result) in
                        model = try! result.get()
                        done()
                    })
                }

                expect(model).notTo( beNil() )
            }
        }

    }
}

