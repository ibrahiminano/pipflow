//
//  WebSocketManager.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation
import Combine

protocol WebSocketManagerProtocol {
    func connect(to url: URL)
    func disconnect()
    func send<T: Encodable>(_ message: T)
    var messagePublisher: AnyPublisher<Data, Never> { get }
    var connectionStatePublisher: AnyPublisher<WebSocketConnectionState, Never> { get }
}

enum WebSocketConnectionState {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case failed(Error)
}

class WebSocketManager: NSObject, WebSocketManagerProtocol {
    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession
    private let encoder = JSONEncoder()
    
    private let messageSubject = PassthroughSubject<Data, Never>()
    private let connectionStateSubject = CurrentValueSubject<WebSocketConnectionState, Never>(.disconnected)
    
    var messagePublisher: AnyPublisher<Data, Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    var connectionStatePublisher: AnyPublisher<WebSocketConnectionState, Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }
    
    override init() {
        self.session = URLSession(configuration: .default)
        super.init()
    }
    
    func connect(to url: URL) {
        connectionStateSubject.send(.connecting)
        
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        connectionStateSubject.send(.connected)
        receiveMessage()
    }
    
    func disconnect() {
        connectionStateSubject.send(.disconnecting)
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        connectionStateSubject.send(.disconnected)
    }
    
    func send<T: Encodable>(_ message: T) {
        guard let webSocketTask = webSocketTask else { return }
        
        do {
            let data = try encoder.encode(message)
            let message = URLSessionWebSocketTask.Message.data(data)
            
            webSocketTask.send(message) { [weak self] error in
                if let error = error {
                    self?.connectionStateSubject.send(.failed(error))
                }
            }
        } catch {
            connectionStateSubject.send(.failed(error))
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self?.messageSubject.send(data)
                case .string(let string):
                    if let data = string.data(using: .utf8) {
                        self?.messageSubject.send(data)
                    }
                @unknown default:
                    break
                }
                
                self?.receiveMessage()
                
            case .failure(let error):
                self?.connectionStateSubject.send(.failed(error))
            }
        }
    }
    
    deinit {
        disconnect()
    }
}