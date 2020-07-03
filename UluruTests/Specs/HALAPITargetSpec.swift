//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Quick
import Nimble
@testable import Uluru

class HALAPITargetSpec: QuickSpec {
    override func spec() {
        TestHelper.markWaitExpecationAsAPIRequest()
        let discovery: ServiceDiscoveryType = ServiceDiscovery.createInstance(apiRootURL: .localDiscoveryURL)
        let service = ServiceRequester<SampleHALAPI>(apiTargetResolver: ServiceRequester<SampleHALAPI>.makeHALTargetResolver(discovery))

        context("HAL Target Resolver") {
            it("should resolve url as expected") {
                let closure = ServiceRequester<SampleHALAPI>.makeHALTargetResolver(discovery)
                let result = closure(.promo(promoGroup: PromoGroup(promoGroupId: "12345")))
                let apiTarget = try! result.get()
                let expectedURL = URL(string: "https://uat02.beta.tab.com.au/v1/invenue-service/promo-groups/12345")!
                expect(apiTarget.url).to(equal( expectedURL ))
            }
        }

        context("URI Linked Entity") {
            var parsed: EmptyDecodableModel?
            waitUntil { done in
                service.request(.fetchWithURL(URL(string: "https://postman-echo.com/get?foo1=bar1&foo2=bar2")!), expecting: EmptyDecodableModel.self) { result in
                    parsed = try? result.get().parsed
                    done()
                }
            }

            it("should provide expected result") {
                expect(parsed).notTo( beNil() )
            }
        }
    }
}

struct PromoGroup: Codable, JSONRepresentable {
    let promoGroupId: String
}

enum SampleHALAPI {
    case promo(promoGroup: JSONRepresentable)
    case fetchWithURL(URL)
}

extension SampleHALAPI: HALAPIDefinition, RequiresHALEntityResolution {
    var entityResolution: EntityResolution {
        switch self {
        case .promo(let promoGroup):
            // Using this enitity "invenue:promo-groups:update":"https://api.beta.tab.com.au/v1/invenue-service/promo-groups/{promoGroupId}",
            return .namedEntity(.init(name: "invenue:promo-groups:update", variables: promoGroup))
        case .fetchWithURL(let url):
            return .linkedEntity(.init(url))
        }
    }

    var method: HTTPMethod {
        return .GET
    }

    var encoding: EncodingStrategy {
        return .dontEncode
    }
}
