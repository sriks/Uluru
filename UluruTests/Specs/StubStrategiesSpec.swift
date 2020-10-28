//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Quick
import Nimble
@testable import Uluru

class StubStrategiesrSpec: QuickSpec {
    override func spec() {
        TestHelper.markWaitExpecationAsAPIRequest()
        var service: ServiceRequester<PostmanEcho>!
        // A sample response model
        struct StubSuccessResponse: Codable, Equatable, JSONRepresentable {
            let animal: String
        }

        // MARK: Stub Strategies
        describe("Stub Strategies") {

            it("should match with provided stub response") {
                let aStubResponse = StubSuccessResponse(animal: "Godzilla")
                service = ServiceRequester(stubStrategy: .stub(delay: 0, response: { (api, target) -> StubResponse in
                    let urlResponse = HTTPURLResponse(url: target.url, statusCode: 200, httpVersion: nil, headerFields: nil)
                    return .networkResponse(urlResponse!, try! aStubResponse.jsonData())
                }))

                waitUntil { done in
                    let _ = service.request(.justGet, expecting: StubSuccessResponse.self, completion: { (result) in
                        expect(result.forceGetParsed(StubSuccessResponse.self)).to( equal(aStubResponse) )
                        done()
                    })
                }
            }

            it("should match to .underlying error when stub returns a network error") {
                let stubedError = NSError(domain: "Godzilla Error", code: 8086, userInfo: nil)
                let stubStrategy: ServiceRequester<PostmanEcho>.StubStrategy = .stub(delay: 0, response: { (api, target) -> StubResponse in
                    return .networkError(stubedError)
                })
                service = ServiceRequester(stubStrategy: stubStrategy)
                var expectedError: NSError?
                waitUntil { done in
                    let _ = service.request(.justGet, expecting: EmptyDecodableModel.self, completion: { (result) in
                        if case .failure(let error) = result, case .underlying(let networkError, _) = error {
                            expectedError = networkError as NSError
                        }
                        done()
                    })
                }

                expect(stubedError).to( equal(expectedError) )
            }

            it("should conditionally invoke response provider and make a real network request when using .continueCourse") {
                var isStubProviderInvoked: Bool = false
                let stubedError = NSError(domain: "Godzilla Error", code: 8086, userInfo: nil)
                let stubStrategy: ServiceRequester<PostmanEcho>.StubStrategy = .stub(delay: 0, response: { (api, target) -> StubResponse in
                    if case .justGet = api {
                        isStubProviderInvoked = true
                        return .continueCourse
                    } else {
                        return .networkError(stubedError)
                    }
                })

                service = ServiceRequester(stubStrategy: stubStrategy)
                var model: EmptyDecodableModel?
                waitUntil { done in
                    let _ = service.request(.justGet, expecting: EmptyDecodableModel.self, completion: { (result) in
                        model = result.forceGetParsed(EmptyDecodableModel.self)
                        done()
                    })
                }

                expect(isStubProviderInvoked).to( beTrue() )
                expect(model).notTo( beNil() )
            }

            it("should cancel a real network request when using .continueCourse") {
                var isStubProviderInvoked: Bool = false
                let stubStrategy: ServiceRequester<PostmanEcho>.StubStrategy = .stub(delay: 0, response: { (api, target) -> StubResponse in
                    isStubProviderInvoked = true
                    return .continueCourse
                })

                service = ServiceRequester(stubStrategy: stubStrategy)
                var model: EmptyDecodableModel?
                var canceller: ServiceCancellable!
                waitUntil { done in
                    canceller = service.request(.justGet, expecting: EmptyDecodableModel.self, completion: { (result) in
                        if case let .success(res) = result {
                            model = res.parsed
                        }
                        done()
                    })
                    canceller.cancel()
                }

                expect(isStubProviderInvoked).to( beTrue() )
                expect(canceller.isCancelled).to( beTrue() )
                expect(model).to( beNil() )
            }


            it("should make real network call when strategy is .dontStub") {
                service = ServiceRequester(stubStrategy: .dontStub)
                var model: EmptyDecodableModel?
                waitUntil { done in
                    let _ = service.request(.justGet, expecting: EmptyDecodableModel.self, completion: { (result) in
                        model = result.forceGetParsed(EmptyDecodableModel.self)
                        done()
                    })
                }

                expect(model).notTo( beNil() )
            }
        }

        describe("StubResponse Helpers") {
            
            context("Using StubResponse.networkResponseFromFile") {
                var theTarget: APITarget!
                let stubStrategy: ServiceRequester<PostmanEcho>.StubStrategy = .stub(delay: 0, response: { (api, target) -> StubResponse in
                    theTarget = target
                    return .networkResponseFromFile("StubSuccessResponse", target: target, in: Bundle(for: type(of: self)))
                })
                service = ServiceRequester(stubStrategy: stubStrategy)
                var response: ParsedDataResponse<StubSuccessResponse>?
                waitUntil { done in
                    let _ = service.request(.justGet, expecting: StubSuccessResponse.self, completion: { (result) in
                        response = try? result.get()
                        done()
                    })
                }

                it("should provide expected model") {
                    expect(response?.parsed.animal).to( equal("Mothra") )
                }

                it("should have urlResponse status code is 200") {
                    expect(response?.dataResponse.urlResponse?.statusCode).to( equal(200) )
                }

                it("should have urlResponse.url same as the target being stubbed") {
                    expect(response?.dataResponse.urlResponse?.url).to( equal(theTarget.url) )
                }
            }

            context("Using StubResponse.networkTimedoutError") {
                let stubStrategy: ServiceRequester<PostmanEcho>.StubStrategy = .stub(delay: 0, response: { (api, target) -> StubResponse in
                    return .networkTimedoutError()
                })
                service = ServiceRequester(stubStrategy: stubStrategy)
                var response: ParsedDataResponse<StubSuccessResponse>?
                var error: ServiceError?
                waitUntil { done in
                    let _ = service.request(.justGet, expecting: StubSuccessResponse.self, completion: { (result) in
                        switch result {
                        case .success(let aResponse):
                            response = aResponse
                        case .failure(let serviceError):
                            error = serviceError
                        }
                        done()
                    })
                }

                it("should not have any response") {
                    expect(response).to( beNil() )
                }

                it("should result in underlying error") {
                    expect(error).to(beSameError(.underlying(NSError(domain: "", code: -1, userInfo: nil), nil)))
                }

                it("should have error as timedout") {
                    var ourUnderlyingError: NSError!
                    guard case let .underlying(theError, _) = error! else {
                        expect(true).to( equal(false) )
                        return
                    }
                    ourUnderlyingError = theError as NSError
                    expect(ourUnderlyingError?.domain).to( equal(NSURLErrorDomain) )
                    expect(ourUnderlyingError?.code).to( equal(NSURLErrorTimedOut) )
                }
            }
        }

    }
}

