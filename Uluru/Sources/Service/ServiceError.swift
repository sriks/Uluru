//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

public enum ServiceError: Error {
    case requestFailed(DataErrorResponse)
    case decodingFailed(DataSuccessResponse, Error)
    case responseError(DataSuccessResponse, JSON)
}
