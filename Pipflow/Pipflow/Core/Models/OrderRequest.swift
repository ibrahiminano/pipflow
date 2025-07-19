//
//  OrderRequest.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation

struct MetaAPIOrderRequest: Codable {
    let symbol: String
    let volume: Double
    let actionType: String
    let stopLoss: Double?
    let takeProfit: Double?
    let comment: String?
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case volume
        case actionType
        case stopLoss
        case takeProfit
        case comment
    }
}