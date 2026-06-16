//
//  WooErrorResponse.swift
//  TrinhsGroup
//
//  Created by longnh on 2025/04/08.
//

import Foundation

struct WooErrorResponse: Codable, LocalizedError {
    let code: String
    let message: String
    let data: WooErrorData?

    var errorDescription: String? {
        "\(code): \(message)"
    }
}

struct WooErrorData: Codable {
    let status: Int?
}
