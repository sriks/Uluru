//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Quick
import Nimble
@testable import Uluru

class ServiceDiscoverySpec: QuickSpec {

    private let apiRootURL = URL(string: "https://uat02.beta.tab.com.au/v1")
    private var serviceDiscovery: ServiceDiscovery!

    override func spec() {
        beforeSuite {
            waitUntil(timeout: 10.0) { done in
                ServiceDiscovery.instantiate(apiRootURL: self.apiRootURL) { result in
                    done()
                }
            }
            self.serviceDiscovery = ServiceDiscovery.shared()
        }

        context("Init service discovery with baseURL") {
            it("should create properly") {
                expect(self.serviceDiscovery).notTo( beNil() )
            }
        }

        context("Add service discovery overlay") {
            it("should add overlay correctly") {
                self.serviceDiscovery.setServiceDiscoveryOverlayEntryRelation(with: "vision:perform:streamformats", uriTemplate: "https://secure.mobile.tabcorp.performgroup.com/streaming/wab/multiformat/index.html{?partnerId,eventId,userId,key}")
                let variables = [
                    "partnerId" : "12345678",
                    "eventId" : "12345678",
                    "userId" : "12345678",
                    "key" : "testKey"
                ]
                let url = self.serviceDiscovery.urlForEntryRelationNamed("vision:perform:streamformats", variables: variables)
                expect(url?.absoluteString).to( equal("https://secure.mobile.tabcorp.performgroup.com/streaming/wab/multiformat/index.html?partnerId=12345678&eventId=12345678&userId=12345678&key=testKey"))
            }
        }

        context("Remove service discovery overlay") {
            it("should remove overlay correctly") {
                self.serviceDiscovery.setServiceDiscoveryOverlayEntryRelation(with: "vision:perform:streamformats", uriTemplate: "https://secure.mobile.tabcorp.performgroup.com/streaming/wab/multiformat/index.html{?partnerId,eventId,userId,key}")
                self.serviceDiscovery.setServiceDiscoveryOverlayEntryRelation(with: "vision:perform:visualisation", uriTemplate: "https://secure.tabcorp.performgroup.com/streaming/watch/event/index.html?visswitch=false&defaultview=vis&{&partnerId,eventId,userId}")
                self.serviceDiscovery.removeServiceDiscoveryOverlayEntryRelation(with: "vision:perform:streamformats")
                let hasStreamFormatsURL = self.serviceDiscovery.hasURLForEntryRelationNamed("vision:perform:streamformats")
                let hasVisualisationURL = self.serviceDiscovery.hasURLForEntryRelationNamed("vision:perform:visualisation")
                expect(hasStreamFormatsURL).notTo( beTrue() )
                expect(hasVisualisationURL).to( beTrue() )
            }
        }

        context("Add service discovery underlay") {
            it("should add overlay correctly") {
                self.serviceDiscovery.setServiceDiscoveryUnderlayEntryRelation(with: "vision:perform:streamformats", uriTemplate: "https://secure.mobile.tabcorp.performgroup.com/streaming/wab/multiformat/index.html{?partnerId,eventId,userId,key}")
                let hasURL = self.serviceDiscovery.hasURLForEntryRelationNamed("vision:perform:streamformats")
                expect(hasURL).to( beTrue() )

                let variables = [
                    "partnerId" : "12345678",
                    "eventId" : "12345678",
                    "userId" : "12345678",
                    "key" : "testKey"
                ]
                let url = self.serviceDiscovery.urlForEntryRelationNamed("vision:perform:streamformats", variables: variables)
                expect(url?.absoluteString).to( equal("https://secure.mobile.tabcorp.performgroup.com/streaming/wab/multiformat/index.html?partnerId=12345678&eventId=12345678&userId=12345678&key=testKey"))
            }
        }

        context("Remove service discovery underlay") {
            it("should remove overlay correctly") {
                self.serviceDiscovery.setServiceDiscoveryUnderlayEntryRelation(with: "vision:perform:streamformats", uriTemplate: "https://secure.mobile.tabcorp.performgroup.com/streaming/wab/multiformat/index.html{?partnerId,eventId,userId,key}")
                self.serviceDiscovery.setServiceDiscoveryUnderlayEntryRelation(with: "vision:perform:visualisation", uriTemplate: "https://secure.tabcorp.performgroup.com/streaming/watch/event/index.html?visswitch=false&defaultview=vis&{&partnerId,eventId,userId}")
                self.serviceDiscovery.removeServiceDiscoveryUnderlayEntryRelation(with: "vision:perform:streamformats")
                let hasStreamFormatsURL = self.serviceDiscovery.hasURLForEntryRelationNamed("vision:perform:streamformats")
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

        context("Set jurisdiction as variable for uriTemplate") {
            it("should constrcut url with jurisdiction correctly") {
                let url = self.serviceDiscovery.urlForEntryRelationNamed("betting:tsn:checkNonLoggedIn", variables: ["jurisdiction" : "NSW"])
                expect(url?.absoluteString).to( equal("https://uat02.beta.tab.com.au/v1/tab-betting-service/NSW/ticket-enquiry") )
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
    }
}
