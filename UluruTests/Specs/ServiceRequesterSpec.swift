//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Quick
import Nimble
@testable import Uluru

class ServiceRequesterSpec: QuickSpec {
    override func spec() {
        TestHelper.markWaitExpecationAsAPIRequest()

        // MARK: Custom JSONDecoder
        context("Custom JSONDecoder") {
            var service: ServiceRequester<PostmanEcho>!
            beforeEach {
                CustomParser.isInvoked = false
                service = ServiceRequester(parser: CustomParser.self)
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
            var service: ServiceRequester<PostmanEcho>!

            beforeEach {
                service = ServiceRequester()
            }

            it("should return placeholder data when provided") {
                var decoded: MockPlaceholder!
                waitUntil { done in
                    let _  = service.request(.justGetWithPlaceholderData, expecting: MockPlaceholder.self) { result in
                        decoded = result.forceGetParsed(MockPlaceholder.self)
                        done()
                    }
                }

                expect(decoded).to( equal(MockPlaceholder()) )
            }

            it("statusCode of placeholder data response is 200") {
                var dataSuccessResponse: DataResponse!
                waitUntil { done in
                    let _ = service.request(.justGetWithPlaceholderData, expecting: EmptyDecodableModel.self, completion: { (result) in
                        dataSuccessResponse = try! result.get().dataResponse
                        done()
                    })
                }

                expect(dataSuccessResponse.urlResponse?.statusCode).to( equal(200) )
            }
        }

        // MARK: Stub Strategies
        context("Stub Strategies") {
            var service: ServiceRequester<PostmanEcho>!

            it("should match with provided stub response") {
                struct StubSuccessResponse: Codable, Equatable, JSONRepresentable {
                    let animal = "Godzilla"
                }
                service = ServiceRequester(stubStrategy: .stub(delay: 0, response: { (api, target) -> StubResponse in
                    let urlResponse = HTTPURLResponse(url: target.url, statusCode: 200, httpVersion: nil, headerFields: nil)
                    return .networkResponse(urlResponse!, try! StubSuccessResponse().jsonData())
                }))

                waitUntil { done in
                    let _ = service.request(.justGet, expecting: StubSuccessResponse.self, completion: { (result) in
                        expect(result.forceGetParsed(StubSuccessResponse.self)).to( equal(StubSuccessResponse()) )
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

        // MARK: Request cancellation
        describe("ServiceCancellable") {
            var service: ServiceRequester<PostmanEcho>!

            it("should return with NSURLErrorCancelled as underlying error") {
                service = ServiceRequester()
                var error: ServiceError?
                var cancellable: ServiceCancellable!
                waitUntil { done in
                    cancellable = service.request(.justGet, expecting: EmptyDecodableModel.self, completion: { (result) in
                        if case let .failure(err) = result {
                            error = err
                        }
                        done()
                    })
                    cancellable.cancel()
                }

                expect(error).notTo( beNil() )
                expect(cancellable.isCancelled).to( beTrue() )
                var isCancelled = false
                if let ourError = error, case let .underlying(underlyingError, _) = ourError  {
                    isCancelled = (underlyingError as NSError).code == NSURLErrorCancelled
                }
                expect(isCancelled).to( beTrue() )
            }
        }
    }
}

class MockCompletionStrategyProvider: RequestCompletionStrategyProvidable {
    private(set) var isInvoked: Bool = false
    let fixed: RequestCompletionStrategy

    init(_ fixed: RequestCompletionStrategy) {
        self.fixed = fixed
    }

    func shouldFinish(_ result: DataResult, api: APIDefinition, decision: @escaping ShouldFinishDecision) {
        isInvoked = true
        decision(fixed)
    }
}

class MockRetryCompletionStrategyProvider: RequestCompletionStrategyProvidable {
    private(set) var isInvoked: Bool = false
    let maxRetries: Int
    let delay: TimeInterval
    private(set) var attemptedRetries: Int = 0

    init(maxRetries: Int, delay: TimeInterval = 0) {
        self.maxRetries = maxRetries
        self.delay = delay
    }

    func shouldFinish(_ result: DataResult, api: APIDefinition, decision: @escaping ShouldFinishDecision) {
        isInvoked = true
        guard attemptedRetries < maxRetries else {
            decision(.goahead)
            return
        }

        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            decision(.retry)
            self.attemptedRetries += 1
        }
    }
}
