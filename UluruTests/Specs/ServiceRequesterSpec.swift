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
