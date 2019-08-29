//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

class ExecutorURLSession: ServiceExecutable {

    func execute(dataRequest request: URLRequest, completion: @escaping ServiceExecutionDataTaskCompletion) -> ServiceCancellable {
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            completion(data, response as! HTTPURLResponse, error) //swiftlint:disable:this force_cast
        }
        task.resume()
        return URLSessionDataTaskCancellableWrapper(dataTask: task)
    }
}

class URLSessionDataTaskCancellableWrapper: ServiceCancellable {
    let dataTask: URLSessionDataTask
    var isCancelled: Bool { return self.dataTask.state == .canceling }

    init(dataTask: URLSessionDataTask) {
        self.dataTask = dataTask
    }

    func cancel() {
        self.dataTask.cancel()
    }
}
