//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
@testable import Uluru

class MockServiceDiscoveryPersistence: ServiceDiscoveryPersistentable {

    var shouldLoadFromFile: Bool { return false }

    func loadServiceDiscoveryFromPersistence(_ completion: (STHALResource?, Error?) -> Void) {
        completion(nil, nil)
    }

    func saveServiceDiscoveryToPersistence(resource: STHALResource, completion: ((Bool, Error?) -> Void)?) {
        completion?(true, nil)
    }
}
