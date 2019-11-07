//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

/// Defines the strategy before completing the request.
/// Use this as the decision maker whether the completion should be invoked or not.
/// For example you may want to check if token expired, restore session and retry.
public enum RequestCompletionStrategy {
    /// Continue with completion
    case goahead

    /// Retry the request
    case retry
}

public typealias ShouldFinishDecision = (_ decision: RequestCompletionStrategy) -> Void

/// Completion Strategy provider
public protocol RequestCompletionStrategyProvidable {

    /// Called before invoking completion with request result.
    ///
    /// - Parameters:
    ///   - result: the final result after reduced from plugins.
    ///   - api: the API in question.
    ///   - decision: completion decision.
    func shouldFinish(_ result: DataResult, api: APIDefinition, decision: @escaping ShouldFinishDecision)
}
