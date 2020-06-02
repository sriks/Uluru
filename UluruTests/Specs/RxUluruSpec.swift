//Copyright © 2020 Tabcorp. All rights reserved.

import Foundation
import RxSwift
import Quick
import Nimble

@testable import Uluru
@testable import RxUluru

class RxUluruSpec: QuickSpec {

    override func spec() {
        describe("Service returning Rx.Single") {
            let service = ServiceRequester<PostmanEcho>(parser: CustomParser.self)
            var isInvoked = false
            waitUntil { done in
                _ = service.rx.request(.justGet, expecting: EmptyDecodableModel.self).subscribe { result in
                    isInvoked = true
                    done()
                }
            }

            it("emits an event") {
                expect(isInvoked).to( beTrue() )
            }
        }
    }
}
