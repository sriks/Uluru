//
//  ServicePluginType.swift
//  TAB
//
//  Created by Sombhatla, Srikanth on 21/2/19.
//  Copyright © 2019 Tabcorp. All rights reserved.
//

import Foundation

public protocol ServicePluginType {
    /// Called to process before sending the request
    func mutate(_ request: URLRequest, target: APIDefinition) -> URLRequest
    
    /// Called before the request is sent over.
    func willSend(_ request: URLRequest, target: APIDefinition)
    
    /// Called after receiving response.
    func didReceive(_ result: DataResult, target: APIDefinition)

    /// Called to modify a result before sending it to caller.
    func willFinish(_ result: DataResult, target: APIDefinition) -> DataResult
}

// MARK: - Default implementation
public extension ServicePluginType {
    func mutate(_ request: URLRequest, target: APIDefinition) -> URLRequest { return request }

    func willSend(_ request: URLRequest, target: APIDefinition) {}
    
    func didReceive(_ result: DataResult, target: APIDefinition) {}

    func willFinish(_ result: DataResult, target: APIDefinition) -> DataResult { return result }
}
