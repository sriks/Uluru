//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

public protocol ServiceCancellable {
    var isCancelled: Bool { get }
    func cancel()
}

public typealias ServiceExecutionDataTaskCompletion = (Data?, HTTPURLResponse?, Error?) -> Void
public protocol ServiceExecutable: class {
    func execute(dataRequest: URLRequest, completion: @escaping ServiceExecutionDataTaskCompletion) -> ServiceCancellable
}
