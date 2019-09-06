//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Nimble

final class TestHelper {
    private init() {}

    /// Sets async timeout expectation longer.
    static func markWaitExpecationAsAPIRequest() {
        Nimble.AsyncDefaults.Timeout = 10
    }

}
