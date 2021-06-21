

import Foundation
import Nimble
@testable import Uluru

final class TestHelper {
    private init() {}

    /// Sets async timeout expectation longer.
    static func markWaitExpecationAsAPIRequest() {
        Nimble.AsyncDefaults.Timeout = 10
    }

    static func markWaitExpectationAsTestingErrors() {
        Nimble.AsyncDefaults.Timeout = 20
    }

}

extension ParsedDataResponseResult {
    /// Handy helper to force get the parsed object.
    func forceGetParsed<T>(_ type: T.Type) -> T where T: Decodable {
        let response = try! get() as! ParsedDataResponse<T>
        return response.parsed
    }

    /// Extracts out associated error from .failure state.
    func error() -> ServiceError? {
        guard case .failure(let error) = self else { return nil }
        return error as? ServiceError
    }
}

/// Helper func to do a predicate on ServiceError matching.
public func beSameError(_ expectedValue: ServiceError) -> Predicate<ServiceError> {
    return Predicate { expression -> PredicateResult in
        var passed = false
        if let value = try expression.evaluate() {
            // We check for the case only since we cannot predict the exact associated values.
            switch value {
            case .underlying:
                switch expectedValue {
                case .underlying:
                    passed = true
                default:
                    break
                }

            case .parsing:
                switch expectedValue {
                case .parsing:
                    passed = true
                default:
                    break
                }

            default:
                break

            }
        }
        return .init(bool: passed, message: .expectedActualValueTo("<\(expectedValue)>"))
    }
}
