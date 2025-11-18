//
//  MetaAPIEndpoint.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation

enum MetaAPIEndpoint: APIEndpoint {
    case linkAccount(login: String, password: String, server: String, platform: TradingPlatform, token: String?)
    case getAccount(accountId: String, token: String?)
    case getPositions(accountId: String, token: String?)
    case getHistory(accountId: String, from: Date, to: Date, token: String?)
    case placeOrder(accountId: String, order: MetaAPIOrderRequest, token: String?)
    case closePosition(accountId: String, positionId: String, token: String?)
    case modifyPosition(accountId: String, positionId: String, stopLoss: Decimal?, takeProfit: Decimal?, token: String?)
    case deployAccount(accountId: String, token: String?)
    case undeployAccount(accountId: String, token: String?)
    case getCurrentUser(token: String?)
    case getCandles(accountId: String, symbol: String, timeframe: String, startTime: Date, limit: Int, token: String?)
    
    var baseURL: String {
        "https://mt-client-api-v1.london.agiliumtrade.ai"
    }
    
    var path: String {
        switch self {
        case .linkAccount:
            return "/users/current/accounts"
        case .getAccount(let accountId, _):
            return "/users/current/accounts/\(accountId)"
        case .getPositions(let accountId, _):
            return "/users/current/accounts/\(accountId)/positions"
        case .getHistory(let accountId, _, _, _):
            return "/users/current/accounts/\(accountId)/history-deals/time"
        case .placeOrder(let accountId, _, _):
            return "/users/current/accounts/\(accountId)/trade"
        case .closePosition(let accountId, let positionId, _):
            return "/users/current/accounts/\(accountId)/positions/\(positionId)"
        case .modifyPosition(let accountId, let positionId, _, _, _):
            return "/users/current/accounts/\(accountId)/positions/\(positionId)"
        case .deployAccount(let accountId, _):
            return "/users/current/accounts/\(accountId)/deploy"
        case .undeployAccount(let accountId, _):
            return "/users/current/accounts/\(accountId)/undeploy"
        case .getCurrentUser:
            return "/users/current"
        case .getCandles(let accountId, _, _, _, _, _):
            return "/users/current/accounts/\(accountId)/historical-candles"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .linkAccount, .placeOrder, .deployAccount, .undeployAccount:
            return .post
        case .getAccount, .getPositions, .getHistory, .getCurrentUser, .getCandles:
            return .get
        case .closePosition:
            return .delete
        case .modifyPosition:
            return .put
        }
    }
    
    var headers: [String: String]? {
        var headers = [String: String]()
        
        switch self {
        case .linkAccount(_, _, _, _, let token),
             .getAccount(_, let token),
             .getPositions(_, let token),
             .getHistory(_, _, _, let token),
             .placeOrder(_, _, let token),
             .closePosition(_, _, let token),
             .modifyPosition(_, _, _, _, let token),
             .deployAccount(_, let token),
             .undeployAccount(_, let token),
             .getCurrentUser(let token),
             .getCandles(_, _, _, _, _, let token):
            if let token = token {
                headers["auth-token"] = token
            }
        }
        
        return headers.isEmpty ? nil : headers
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .getHistory(_, let from, let to, _):
            let formatter = ISO8601DateFormatter()
            return [
                "startTime": formatter.string(from: from),
                "endTime": formatter.string(from: to)
            ]
        case .getCandles(_, let symbol, let timeframe, let startTime, let limit, _):
            let formatter = ISO8601DateFormatter()
            return [
                "symbol": symbol,
                "timeframe": timeframe,
                "startTime": formatter.string(from: startTime),
                "limit": limit
            ]
        default:
            return nil
        }
    }
    
    var body: Data? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        switch self {
        case .linkAccount(let login, let password, let server, let platform, _):
            let body = [
                "login": login,
                "password": password,
                "server": server,
                "platform": platform.rawValue.lowercased(),
                "name": "Trading Account"
            ]
            return try? JSONSerialization.data(withJSONObject: body)
            
        case .placeOrder(_, let order, _):
            return try? encoder.encode(order)
            
        case .modifyPosition(_, _, let stopLoss, let takeProfit, _):
            var body = [String: Any]()
            if let stopLoss = stopLoss {
                body["stopLoss"] = "\(stopLoss)"
            }
            if let takeProfit = takeProfit {
                body["takeProfit"] = "\(takeProfit)"
            }
            return try? JSONSerialization.data(withJSONObject: body)
            
        default:
            return nil
        }
    }
}