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

enum WebSocketConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case failed(Error)
    case reconnecting(attempt: Int)
    
    static func == (lhs: WebSocketConnectionState, rhs: WebSocketConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected),
             (.disconnecting, .disconnecting):
            return true
        case (.failed(_), .failed(_)):
            return true
        case (.reconnecting(let a1), .reconnecting(let a2)):
            return a1 == a2
        default:
            return false
        }
    }
    
    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

class WebSocketManager: NSObject, WebSocketManagerProtocol {
    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession
    private let encoder = JSONEncoder()
    
    private let messageSubject = PassthroughSubject<Data, Never>()
    private let connectionStateSubject = CurrentValueSubject<WebSocketConnectionState, Never>(.disconnected)
    
    // Connection management
    private var currentURL: URL?
    private var reconnectTimer: Timer?
    private var reconnectAttempt = 0
    private let maxReconnectAttempts = 5
    private let reconnectDelay: TimeInterval = 5.0
    
    // Heartbeat/Keep-alive
    private var pingTimer: Timer?
    private let pingInterval: TimeInterval = 30.0
    private var lastPongTime = Date()
    
    // Auto-reconnect flag
    private var shouldAutoReconnect = true
    private var isManualDisconnect = false
    
    var messagePublisher: AnyPublisher<Data, Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    var connectionStatePublisher: AnyPublisher<WebSocketConnectionState, Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }
    
    override init() {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
        
        self.session = URLSession(configuration: configuration)
        super.init()
    }
    
    func connect(to url: URL) {
        currentURL = url
        isManualDisconnect = false
        reconnectAttempt = 0
        
        connectionStateSubject.send(.connecting)
        
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Wait for actual connection confirmation
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                self?.handleConnectionError(error)
            } else {
                self?.connectionStateSubject.send(.connected)
                self?.startHeartbeat()
                self?.receiveMessage()
            }
        }
    }
    
    func disconnect() {
        isManualDisconnect = true
        connectionStateSubject.send(.disconnecting)
        
        stopHeartbeat()
        stopReconnectTimer()
        
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
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self.messageSubject.send(data)
                case .string(let string):
                    if let data = string.data(using: .utf8) {
                        self.messageSubject.send(data)
                    }
                @unknown default:
                    break
                }
                
                // Continue receiving messages
                self.receiveMessage()
                
            case .failure(let error):
                self.handleConnectionError(error)
            }
        }
    }
    
    // MARK: - Connection Management
    
    private func handleConnectionError(_ error: Error) {
        connectionStateSubject.send(.failed(error))
        
        // Check if we should attempt reconnection
        if !isManualDisconnect && shouldAutoReconnect && reconnectAttempt < maxReconnectAttempts {
            scheduleReconnect()
        }
    }
    
    private func scheduleReconnect() {
        reconnectAttempt += 1
        connectionStateSubject.send(.reconnecting(attempt: reconnectAttempt))
        
        stopReconnectTimer()
        
        let delay = reconnectDelay * Double(reconnectAttempt)
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self, let url = self.currentURL else { return }
            print("Attempting reconnection #\(self.reconnectAttempt)")
            self.connect(to: url)
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    // MARK: - Heartbeat Management
    
    private func startHeartbeat() {
        stopHeartbeat()
        
        pingTimer = Timer.scheduledTimer(withTimeInterval: pingInterval, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopHeartbeat() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func sendPing() {
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                print("Ping failed: \(error)")
                self?.handleConnectionError(error)
            } else {
                self?.lastPongTime = Date()
            }
        }
    }
    
    deinit {
        disconnect()
    }
}