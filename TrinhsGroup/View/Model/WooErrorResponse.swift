//
//  WooErrorResponse.swift
//  TrinhsGroup
//
//  Created by longnh on 2025/04/08.
//

struct WooErrorResponse: Codable, Error {
    let code: String
    let message: String
    let data: WooErrorData?
}

struct WooErrorData: Codable {
    let status: Int?
}
