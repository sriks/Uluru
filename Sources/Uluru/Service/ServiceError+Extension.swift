/**

 Convenience  property for a network connection error

 */
extension NSError {

    private enum Constant {
        static let networkErrors: [URLError.Code] = [.networkConnectionLost,
                                                     .notConnectedToInternet]
    }

    /**

     Convenience property to indicate if there is an internet connection error or not

     */
    public var isNetworkConnectionError: Bool {
        let urlErrorCode = URLError.Code(rawValue: code)
        return domain == NSURLErrorDomain && Constant.networkErrors.contains(urlErrorCode)
    }
}

/**

 Convenience functions to get underlying errors

 */
extension ServiceError {

    var nsError: NSError? {
        guard case let .underlying(underlyingError, _) = self else {
            return nil
        }
        return underlyingError as NSError
    }

    /**

     Returns an underlying URLError.Code if available

     */
    var urlErrorCode: URLError.Code? {
        guard let error = nsError else {
            return nil
        }
        return URLError.Code(rawValue: error.code)
    }

    /**

     Convenience property to indicate if there is an internet connection error or not

     */
    public var isNetworkConnectionError: Bool {
        return nsError?.isNetworkConnectionError == true
    }

}
