//
//  NetworkAdapter.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import Foundation
import UIKit
import SwiftyJSON

enum ErrorCode: Int {
    case none = -1
    case unknown = 10000
    case connection = 9999
    case expiredToken = 401
    case notModified = 304
    case useProxy = 305
    case badRequest = 400
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case requestTimeout = 408
    case internalServerError = 500
    case serviceUnavailabel = 503
    case gatewayTimeout = 504
    
    var message: String {
        switch self {
        case .unknown:
            return "Error. Please try again!"
        case .connection:
            return "No internet connection!"
        case .notModified:
            return "Not modified"
        case .useProxy:
            return "Use Proxy"
        case .badRequest:
            return "Bad Request"
        case .forbidden:
            return "Forbidden"
        case .notFound:
            return "Not Found"
        case .methodNotAllowed:
            return "Method Not Allowed"
        case .requestTimeout:
            return "Request Timeout"
        case .internalServerError:
            return "Internal Server Error"
        case .serviceUnavailabel:
            return "Service Unavailable"
        case .gatewayTimeout:
            return "Gateway Timeout"
        default:
            return ""
        }
    }
}

struct AppError {
    var statusCode: Int     = 0
    var message: String     = ""
    
    init(code: ErrorCode) {
        self.statusCode = code.rawValue
        self.message = code.message
    }
    
    init(code: Int) {
        let errorCode = ErrorCode(rawValue: code) ?? .unknown
        self.message = errorCode.message
    }
    
    init(json: JSON) {
        self.message = json["errorMessage"].stringValue
    }
    
    init(message: String) {
        self.statusCode = ErrorCode.unknown.rawValue
        self.message = message
    }
}
