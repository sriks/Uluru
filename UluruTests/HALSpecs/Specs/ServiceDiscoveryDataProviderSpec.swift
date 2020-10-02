//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Quick
import Nimble
@testable import Uluru

class ServiceDiscoveryDataProviderSpec: QuickSpec {

    private let apiRootURL = URL(string: "https://uat02.beta.tab.com.au/v1")

    override func spec() {

        TestHelper.markWaitExpecationAsAPIRequest()

        context("init data provider at the first time") {
            let mockPersistence = MockServiceDiscoveryPersistence()
            let mockNetworkService = MockServiceDiscoveryNetworking(apiRootURL: URL(string: "Test")!, bearerToken: "Test")
            let dataProvider = ServiceDiscoveryDataProvider(service: mockNetworkService, persistence: mockPersistence)

            beforeSuite {
                waitUntil { done in
                    dataProvider.load { _ in
                        done()
                    }
                }
            }

            it("should update lastUpdateDate to now") {
                if let lastUpdateDate = dataProvider.serviceDiscoveryLastUpdatedDate {
                    let lastUpdateDateTimeinterval = lastUpdateDate.timeIntervalSinceNow
                    let nowTimeInterval = Date().timeIntervalSinceNow
                    let oneMinuteTimeInterval: TimeInterval = 60
                    let timeIntervalDiff = nowTimeInterval - lastUpdateDateTimeinterval
                    expect(timeIntervalDiff).to( beLessThan(oneMinuteTimeInterval) )
                }
            }

            it("should initialise an empty overlay") {
                expect(dataProvider.serviceDiscoveryOverlay).to( beEmpty() )
            }

            it("should initialise an empty underlay") {
                expect(dataProvider.serviceDiscoveryUnderlay).to( beEmpty() )
            }

            it("should load uri template from mock service") {
                expect(dataProvider.serviceDiscoveryResource).notTo( beNil() )
                expect(dataProvider.serviceDiscoveryResource?.payload).notTo( beNil() )
                expect(dataProvider.serviceDiscoveryResource?.links.relationNames.count).to( equal(4) )
            }
        }

        context("refresh service discovery after 6 mins") {
            let persistence = MockServiceDiscoveryPersistence()
            let service = MockServiceDiscoveryNetworking(apiRootURL: URL(string: "Test")!, bearerToken: "Test")
            let dataProvider = ServiceDiscoveryDataProvider(service: service, persistence: persistence)
            let sixMinutesAgo: TimeInterval = -6*60
            dataProvider.serviceDiscoveryLastUpdatedDate = Date(timeIntervalSinceNow: sixMinutesAgo)

            it("should refresh service discovery without errors") {
                dataProvider.requestServiceDiscovery { result in
                    switch result {
                    case .success:
                        expect(dataProvider.serviceDiscoveryResource).notTo( beNil() )
                    case .failure(_):
                        break
                    }
                }
            }
        }

        context("refresh service discovery within 5 mins") {
            let persistence = MockServiceDiscoveryPersistence()
            let service = MockServiceDiscoveryNetworking(apiRootURL: URL(string: "Test")!, bearerToken: "Test")
            let dataProvider = ServiceDiscoveryDataProvider(service: service, persistence: persistence)
            let fourMinutesAgo: TimeInterval = -4*60
            dataProvider.serviceDiscoveryLastUpdatedDate = Date(timeIntervalSinceNow: fourMinutesAgo)

            it("should show request service discovery too often error") {
                dataProvider.requestServiceDiscovery { result in
                    switch result {
                    case .success:
                        break
                    case .failure(let error):
                        expect(error).notTo( beNil() )
                        expect(error).to( equal(.discoveryIsUpToDate) )
                        expect(error.errorDescription).to( equal("Service Discovery refreshs too often") )
                    }
                }
            }
        }
    }
}
