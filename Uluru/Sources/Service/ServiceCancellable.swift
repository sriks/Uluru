//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

/// Protocol capability to cancel a service request.
public protocol ServiceCancellable {
    var isCancelled: Bool { get }
    func cancel()
}

/// A wrapper to hold an internal replacable cancellable.
class ServiceCancellableWrapper: ServiceCancellable {
    var inner: ServiceCancellable = DummyCancellable()
    var isCancelled: Bool { return inner.isCancelled }

    func cancel() {
        inner.cancel()
    }
}

/// A dummy implementation without any side effects.
private class DummyCancellable: ServiceCancellable {
    private(set) var isCancelled: Bool = false

    func cancel() {
        isCancelled = true
    }
}

