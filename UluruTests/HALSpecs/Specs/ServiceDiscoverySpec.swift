//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Quick
import Nimble
@testable import Uluru

class ServiceDiscoverySpec: QuickSpec {

    private let apiRootURL: URL = .localDiscoveryURL
    private var serviceDiscovery: ServiceDiscoveryType!

    override func spec() {
        TestHelper.markWaitExpecationAsAPIRequest()
        beforeSuite {
            waitUntil { done in
                self.serviceDiscovery = ServiceDiscovery.createInstance(apiRootURL: self.apiRootURL)
                done()
            }
        }

        context("Init service discovery with baseURL") {
            var sharedInstance: ServiceDiscoveryType?
            waitUntil { done in
                ServiceDiscovery.instantiate(apiRootURL: .localDiscoveryURL) { result in
                    done()
                }
            }
            sharedInstance = ServiceDiscovery.shared()

            it("should create properly") {
                expect(sharedInstance).notTo( beNil() )
            }
        }

        context("Add service discovery overlay") {
            it("should add overlay correctly") {
                // Here we use an UUID to ensure a unique reference is being added so it wont overwrite any internal shared states.
                let visionPerformStreamFormats = "vision:perform:streamformats-\(UUID().uuidString)"
                self.serviceDiscovery.setServiceDiscoveryOverlayEntryRelation(with: visionPerformStreamFormats, uriTemplate: "https://secure.mobile.tabcorp.performgroup.com/streaming/wab/multiformat/index.html{?partnerId,eventId,userId,key}")
                let variables = [
                    "partnerId" : "12345678",
                    "eventId" : "12345678",
                    "userId" : "12345678",
                    "key" : "testKey"
                ]
                let url = self.serviceDiscovery.urlForEntryRelationNamed(visionPerformStreamFormats, variables: variables)
                expect(url?.absoluteString).to( equal("https://secure.mobile.tabcorp.performgroup.com/streaming/wab/multiformat/index.html?partnerId=12345678&eventId=12345678&userId=12345678&key=testKey"))
            }
        }

        context("Remove service discovery overlay") {
            it("should remove overlay correctly") {
                // Here we use an UUID to ensure a unique reference is being added so it wont overwrite any internal shared states.
                let visionPerformStreamFormats = "vision:perform:streamformats-\(UUID().uuidString)"
                self.serviceDiscovery.setServiceDiscoveryOverlayEntryRelation(with: visionPerformStreamFormats, uriTemplate: "https://secure.mobile.tabcorp.performgroup.com/streaming/wab/multiformat/index.html{?partnerId,eventId,userId,key}")
                self.serviceDiscovery.setServiceDiscoveryOverlayEntryRelation(with: "vision:perform:visualisation", uriTemplate: "https://secure.tabcorp.performgroup.com/streaming/watch/event/index.html?visswitch=false&defaultview=vis&{&partnerId,eventId,userId}")
                self.serviceDiscovery.removeServiceDiscoveryOverlayEntryRelation(with: visionPerformStreamFormats)
                let hasStreamFormatsURL = self.serviceDiscovery.hasURLForEntryRelationNamed(visionPerformStreamFormats)
                let hasVisualisationURL = self.serviceDiscovery.hasURLForEntryRelationNamed("vision:perform:visualisation")
                expect(hasStreamFormatsURL).notTo( beTrue() )
                expect(hasVisualisationURL).to( beTrue() )
            }
        }

        context("Add service discovery underlay") {
            it("should add overlay correctly") {
                // Here we use an UUID to ensure a unique reference is being added so it wont overwrite any internal shared states.
                let visionPerformStreamFormats = "vision:perform:streamformats-\(UUID().uuidString)"
                self.serviceDiscovery.setServiceDiscoveryUnderlayEntryRelation(with: visionPerformStreamFormats, uriTemplate: "https://secure.mobile.tabcorp.performgroup.com/streaming/wab/multiformat/index.html{?partnerId,eventId,userId,key}")
                let hasURL = self.serviceDiscovery.hasURLForEntryRelationNamed(visionPerformStreamFormats)
                expect(hasURL).to( beTrue() )

                let variables = [
                    "partnerId" : "12345678",
                    "eventId" : "12345678",
                    "userId" : "12345678",
                    "key" : "testKey"
                ]
                let url = self.serviceDiscovery.urlForEntryRelationNamed(visionPerformStreamFormats, variables: variables)
                expect(url?.absoluteString).to( equal("https://secure.mobile.tabcorp.performgroup.com/streaming/wab/multiformat/index.html?partnerId=12345678&eventId=12345678&userId=12345678&key=testKey"))
            }
        }

        context("Remove service discovery underlay") {
            it("should remove overlay correctly") {
                // Here we use an UUID to ensure a unique reference is being added so it wont overwrite any internal shared states.
                let visionPerformStreamFormats = "vision:perform:streamformats-\(UUID().uuidString)"
                self.serviceDiscovery.setServiceDiscoveryUnderlayEntryRelation(with: visionPerformStreamFormats, uriTemplate: "https://secure.mobile.tabcorp.performgroup.com/streaming/wab/multiformat/index.html{?partnerId,eventId,userId,key}")
                self.serviceDiscovery.setServiceDiscoveryUnderlayEntryRelation(with: "vision:perform:visualisation", uriTemplate: "https://secure.tabcorp.performgroup.com/streaming/watch/event/index.html?visswitch=false&defaultview=vis&{&partnerId,eventId,userId}")
                self.serviceDiscovery.removeServiceDiscoveryUnderlayEntryRelation(with: visionPerformStreamFormats)
                let hasStreamFormatsURL = self.serviceDiscovery.hasURLForEntryRelationNamed(visionPerformStreamFormats)
                let hasVisualisationURL = self.serviceDiscovery.hasURLForEntryRelationNamed("vision:perform:visualisation")
                expect(hasStreamFormatsURL).notTo( beTrue() )
                expect(hasVisualisationURL).to( beTrue() )
            }
        }

        context("Set account number as variable for uriTemplate") {
            it("should constrcut url with account number correctly") {
                let url = self.serviceDiscovery.urlForEntryRelationNamed("account:acknowledge-anniversary", variables: ["accountNumber" : "828319"])
                expect(url?.absoluteString).to( equal("https://uat02.beta.tab.com.au/v1/account-service/tab/accounts/828319/acknowledge/anniversary") )
            }
        }

        context("Set default env parameters as variable for uriTemplate") {
            it("should constrcut url with default env parameters correctly") {
                let variables = [
                    "platform" : "iphone",
                    "platformVersion" : "11.4",
                    "version" : "10.23.1",
                    "applicationId" : "au.com.tabcorp.tab"
                ]
                let url = self.serviceDiscovery.urlForEntryRelationNamed("application:config", variables: variables)
                expect(url?.absoluteString).to( equal("https://uat02.beta.tab.com.au/v1/application-service/config?platform=iphone&applicationId=au.com.tabcorp.tab&version=10.23.1&platformVersion=11.4") )
            }
        }

        // Here we have to make a real API call to test the internal mechanics to ensure it indeed works.
        context("Should be able to fetch discovery from network") {
            var discovery: ServiceDiscoveryType!
            var isSuccess: Bool = false
            beforeSuite {
                waitUntil { done in
                    // Using prod url since non-prod urls can give 503 very often during nights.
                    discovery = ServiceDiscovery.createInstance(apiRootURL: URL(string: "https://api.beta.tab.com.au/v1/")!) { result in
                        switch result {
                        case .success:
                            isSuccess = true
                        case .failure:
                            isSuccess = false
                        }
                        done()
                    }
                }
            }

            it("should have loaded successfully") {
                expect(isSuccess).to( beTrue() )
                expect(discovery).notTo( beNil() )
            }
        }
    }
}
