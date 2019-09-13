//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

public class ExecutorURLSession: ServiceExecutable {

    public func execute(dataRequest request: URLRequest, completion: @escaping ServiceExecutionDataTaskCompletion) -> ServiceCancellable {
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            completion(data, response as? HTTPURLResponse, error)
        }
        task.resume()
        return URLSessionDataTaskCancellableWrapper(dataTask: task)
    }
}

public extension ExecutorURLSession {
    static func make() -> ServiceExecutable {
        return ExecutorURLSession()
    }
}

public class URLSessionDataTaskCancellableWrapper: ServiceCancellable {
    let dataTask: URLSessionDataTask
    public var isCancelled: Bool { return self.dataTask.state == .canceling }

    init(dataTask: URLSessionDataTask) {
        self.dataTask = dataTask
    }

    public func cancel() {
        self.dataTask.cancel()
    }
}
