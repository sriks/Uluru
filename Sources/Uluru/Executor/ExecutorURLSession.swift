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
    private let dataTask: URLSessionDataTask
    private var markCancelled = false
    public var isCancelled: Bool { return markCancelled }

    init(dataTask: URLSessionDataTask) {
        self.dataTask = dataTask
    }

    public func cancel() {
        // task state cannot be used here since it takes time to reflect.
        markCancelled = true
        self.dataTask.cancel()
    }
}
