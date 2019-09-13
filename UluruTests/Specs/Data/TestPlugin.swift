//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
@testable import Uluru

class PluginInvocationCount {
    var mutateRequest: Int = 0
    var willSubmitRequest: Int = 0
    var didReceiveResult: Int = 0
    var mutateResult: Int = 0
}

class TestErrorPlugin: ServicePluginType {
    let invocationCount = PluginInvocationCount()
    var didMutate: Bool = false
    var didRecieveResponse: Bool = false
    var errorWithLove = NSError(domain: "plugin", code: -1, userInfo: ["animal": "godzilla"])

    func mutate(_ request: URLRequest, api: APIDefinition) -> URLRequest {
        invocationCount.mutateRequest += 1
        var ourRequest = request
        ourRequest.addValue("godzilla", forHTTPHeaderField: "animal")
        return ourRequest
    }

    func willSubmit(_ request: URLRequest, api: APIDefinition) {
        invocationCount.willSubmitRequest += 1
        // To ensure we did mutate the request earlier.
        didMutate = (request.value(forHTTPHeaderField: "animal") == "godzilla")
    }

    func didReceive(_ result: DataResult, api: APIDefinition) {
        invocationCount.didReceiveResult += 1
        didRecieveResponse = true
    }

    func mutate(_ result: DataResult, api: APIDefinition) -> DataResult {
        invocationCount.mutateResult += 1
        return .failure(.underlying(errorWithLove, nil))
    }
}

class TestSuccessPlugin: TestErrorPlugin {
    override func mutate(_ result: DataResult, api: APIDefinition) -> DataResult {
        super.invocationCount.mutateResult += 1
        return result
    }
}

