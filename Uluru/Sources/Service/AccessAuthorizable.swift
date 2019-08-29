//
//  AccessAuthorizable.swift
//  Wager
//
//  Created by Sombhatla, Srikanth on 26/2/19.
//  Copyright © 2019 Tabcorp. All rights reserved.
//

import Foundation

public enum TypeOfAuthorization {
    case none
    case basic
    case bearer
    case custom(String)
    
    var value: String? {
        switch self {
        case .none: return nil
        case .basic: return "Basic"
        case .bearer: return "Bearer"
        case .custom(let customValue): return customValue
        }
    }
}

public protocol AccessAuthorizable {
    var authorizationType: TypeOfAuthorization { get }
}

