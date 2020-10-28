//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Quick
import Nimble
@testable import Uluru

/// Tests the functionality of Plugin system
class PluginsSpec: QuickSpec {
    override func spec() {
        TestHelper.markWaitExpecationAsAPIRequest()
        var service: ServiceRequester<PostmanEcho>!
        var plugin: TestErrorPlugin!

        beforeEach {
            plugin = TestErrorPlugin()
            service = ServiceRequester(plugins: [plugin])
        }

        it("will let plugin mutate request before sending") {
            waitUntil { done in
                let _ = service.request(.justGet, expecting: EmptyDecodableModel.self) { result in
                    done()
                }
            }

            expect(plugin.didMutate).to( beTrue() )
        }


        it("informs plugin that response recieved") {
            waitUntil { done in
                let _ = service.request(.justGet, expecting: EmptyDecodableModel.self) { result in
                    done()
                }
            }

            expect(plugin.didRecieveResponse).to( beTrue() )
        }

        it("will let plugin to mutate response") {
            var theError: NSError!
            waitUntil { done in
                let _ = service.request(PostmanEcho.justGet, expecting: EmptyDecodableModel.self) { result in
                    if case let .failure(serviceError) = result, case .underlying(let error, _) = serviceError {
                        theError = error as NSError
                    }
                    done()
                }
            }

            expect(theError).to( equal(plugin.errorWithLove) )
        }
    }
}
