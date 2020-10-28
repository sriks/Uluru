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
    func mutate(_ request: URLRequest, api: APIDefinition) -> URLRequest
    
    /// Called before the request is sent over.
    func willSubmit(_ request: URLRequest, api: APIDefinition)
    
    /// Called after receiving response.
    func didReceive(_ result: DataResult, api: APIDefinition)

    /// Called to modify a result before sending it to caller.
    func mutate(_ result: DataResult, api: APIDefinition) -> DataResult
}

// MARK: - Default implementation
public extension ServicePluginType {
    func mutate(_ request: URLRequest, api: APIDefinition) -> URLRequest { return request }

    func willSubmit(_ request: URLRequest, api: APIDefinition) {}
    
    func didReceive(_ result: DataResult, api: APIDefinition) {}

    func mutate(_ result: DataResult, api: APIDefinition) -> DataResult { return result }
}
