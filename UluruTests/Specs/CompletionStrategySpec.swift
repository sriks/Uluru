//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Quick
import Nimble
@testable import Uluru

class CompletionStrategySpec: QuickSpec {
    override func spec() {
        TestHelper.markWaitExpecationAsAPIRequest()
        
        context("When completion strategy is .goahead") {
            var service: ServiceProvider<PostmanEcho>!

            it("should return the expected result") {
                let completionProvider = MockCompletionStrategyProvider(.goahead)
                service = ServiceProvider(completionStrategy: completionProvider)
                var model: EmptyDecodableModel?
                waitUntil { done in
                    let _ = service.request(.justGet, expecting: EmptyDecodableModel.self, completion: { (result) in
                        model = result.forceGetParsed(EmptyDecodableModel.self)
                        done()
                    })
                }

                expect(completionProvider.isInvoked).to( beTrue() )
                expect(model).notTo( beNil() )
            }
        }

        context("When completion strategy is .retry") {
            var service: ServiceProvider<PostmanEcho>!

            it("should retry request as expected") {
                let completionProvider = MockRetryCompletionStrategyProvider(maxRetries: 2,delay: 2)
                service = ServiceProvider(completionStrategy: completionProvider)
                var model: EmptyDecodableModel!
                waitUntil { done in
                    let _ = service.request(.justGet, expecting: EmptyDecodableModel.self, completion: { (result) in
                        model = result.forceGetParsed(EmptyDecodableModel.self)
                        done()
                    })
                }

                expect(completionProvider.isInvoked).to( beTrue() )
                // Ensure retry attempts do match
                expect(completionProvider.maxRetries).to( equal(completionProvider.attemptedRetries) )
                // Check we indeed got the model
                expect(model).notTo( beNil() )
            }

            it("should invoke plugins on every retry") {
                let completionProvider = MockRetryCompletionStrategyProvider(maxRetries: 2)
                // +1 because the retries are applied after the first attempt.
                let expectedInvocations = completionProvider.maxRetries + 1

                let aPlugin = TestSuccessPlugin()
                service = ServiceProvider(plugins: [aPlugin], completionStrategy: completionProvider)
                var model: EmptyDecodableModel!

                waitUntil { done in
                    let _ = service.request(.justGet, expecting: EmptyDecodableModel.self, completion: { (result) in
                        model = result.forceGetParsed(EmptyDecodableModel.self)
                        done()
                    })
                }

                expect(model).notTo( beNil() )
                expect(aPlugin.invocationCount.mutateRequest).to( equal(expectedInvocations) )
                expect(aPlugin.invocationCount.willSubmitRequest).to( equal(expectedInvocations) )
                expect(aPlugin.invocationCount.didReceiveResult).to( equal(expectedInvocations) )
                expect(aPlugin.invocationCount.mutateResult).to( equal(expectedInvocations) )
            }

            it("should invoke completion handler only once irrespective of retries") {
                let completionProvider = MockRetryCompletionStrategyProvider(maxRetries: 2)
                service = ServiceProvider(completionStrategy: completionProvider)
                var actualCompletionInvocations = 0
                waitUntil { done in
                    let _ = service.request(.justGet, expecting: EmptyDecodableModel.self, completion: { (result) in
                        actualCompletionInvocations += 1
                        done()
                    })
                }

                expect(actualCompletionInvocations).to( equal(1) )
            }

        }

    }
}
