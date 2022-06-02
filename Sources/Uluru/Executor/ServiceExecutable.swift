import Foundation

public typealias ServiceExecutionDataTaskCompletion = (Data?, HTTPURLResponse?, Error?) -> Void
public protocol ServiceExecutable: AnyObject {
    func execute(dataRequest: URLRequest, completion: @escaping ServiceExecutionDataTaskCompletion) -> ServiceCancellable
}
