//
//  ChatManager.swift
//  Veramo App
//
//  Created by rentamac on 12/9/25.
//

import Foundation
import SwiftUI
import Combine
import StreamChat
import StreamChatSwiftUI

class ChatManager: ObservableObject {
    static let shared = ChatManager()
    
    private(set) var chatClient: ChatClient?
    @Published var isConnected = false
    @Published var connectionError: String?
    
    // Track if we're currently connecting to prevent duplicate connections
    @Published private(set) var isConnecting = false
    
    private let apiKey = "j46xbwqsrzsk"
    
    private init() {
        setupChatClient()
    }
    
    private func setupChatClient() {
        var config = ChatClientConfig(apiKey: .init(apiKey))
        config.isLocalStorageEnabled = true
        
        chatClient = ChatClient(config: config)
        
    }
    
    func connectUser(customer: AuthenticatedCustomer, token: String) {
        guard let chatClient = chatClient else {
            connectionError = "Chat client not initialized"
            return
        }
        
        // Prevent duplicate connections
        if isConnecting {
            print("⏳ [CHAT] Connection already in progress, ignoring duplicate request")
            return
        }
        
        // If already connected, disconnect first to ensure clean state
        if isConnected {
            print("⚠️ [CHAT] Already connected, disconnecting previous user...")
            Task {
                await disconnect()
                // After disconnect completes, connect the new user
                await MainActor.run {
                    self.performConnection(customer: customer, token: token)
                }
            }
        } else {
            performConnection(customer: customer, token: token)
        }
    }
    
    private func performConnection(customer: AuthenticatedCustomer, token: String) {
        guard let chatClient = chatClient else {
            connectionError = "Chat client not initialized"
            return
        }
        
        // Set connecting state
        isConnecting = true
        
        let userInfo = UserInfo(
            id: "customer-\(customer.id)",
            name: customer.name,
            imageURL: nil
        )
        
        print("🔌 [CHAT] Connecting user: \(customer.name ?? "Unknown") (ID: customer-\(customer.id))")
        
        chatClient.connectUser(userInfo: userInfo, token: .init(stringLiteral: token)) { [weak self] error in
            DispatchQueue.main.async {
                // Clear connecting state
                self?.isConnecting = false
                
                if let error = error {
                    print("❌ [CHAT] Connection failed: \(error.localizedDescription)")
                    self?.isConnected = false
                    self?.connectionError = error.localizedDescription
                } else {
                    print("✅ [CHAT] Connection successful")
                    self?.isConnected = true
                    self?.connectionError = nil
                }
            }
        }
    }
    
    func disconnect() async {
        print("🔌 [CHAT] Disconnecting user...")
        
        // Clear connecting state if it was in progress
        await MainActor.run {
            isConnecting = false
        }
        
        // Disconnect from Stream
        await chatClient?.disconnect()
        
        // Clear local state
        await MainActor.run {
            isConnected = false
            connectionError = nil
            print("✅ [CHAT] Disconnected successfully")
        }
    }
    
    func resetAndClearData() async {
        print("🗑️ [CHAT] Resetting chat client and clearing local data...")
        
        // Disconnect first
        await disconnect()
        
        // Reset the entire client to clear all local data
        await MainActor.run {
            // Recreate the client from scratch, which clears all cached data
            setupChatClient()
            print("✅ [CHAT] Chat client reset and data cleared")
        }
    }
}
