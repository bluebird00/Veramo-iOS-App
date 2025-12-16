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
    
    // API key will be set dynamically from backend response
    private var apiKey: String?
    
    private init() {
        // Don't setup client yet - wait for API key from backend
    }
    
    private func setupChatClient(apiKey: String) {
        // Only setup if we don't have a client or the API key changed
        if chatClient == nil || self.apiKey != apiKey {
            self.apiKey = apiKey
            var config = ChatClientConfig(apiKey: .init(apiKey))
            config.isLocalStorageEnabled = true
            
            chatClient = ChatClient(config: config)
            print("✅ [CHAT] Chat client initialized with API key: \(String(apiKey.prefix(8)))...")
        }
    }
    
    func connectUser(customer: AuthenticatedCustomer, token: String, apiKey: String) {
        // Setup chat client with the provided API key
        setupChatClient(apiKey: apiKey)
        
        guard let chatClient = chatClient else {
            connectionError = "Chat client not initialized"
            return
        }
        
        // Prevent duplicate connections
        if isConnecting {
            print("⏳ [CHAT] Connection already in progress, ignoring duplicate request")
            return
        }
        
        let userId = "customer-\(customer.id)"
        
        // Check if we're already connected as this user
        if isConnected && chatClient.currentUserId == userId {
            print("✅ [CHAT] Already connected as \(userId), skipping connection")
            return
        }
        
        // If already connected as a different user, disconnect first to ensure clean state
        if isConnected {
            print("⚠️ [CHAT] Already connected as \(chatClient.currentUserId ?? "unknown"), disconnecting previous user...")
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
        print("🔑 [CHAT] Token preview: \(String(token.prefix(20)))...")
        
        // Create timeout task
        let timeoutTask = Task {
            try? await Task.sleep(for: .seconds(30))
            if isConnecting {
                print("⏰ [CHAT] Connection timeout after 30 seconds")
                await MainActor.run {
                    self.isConnecting = false
                    self.connectionError = "Connection timeout. Please check your internet connection and try again."
                }
            }
        }
        
        chatClient.connectUser(userInfo: userInfo, token: .init(stringLiteral: token)) { [weak self] error in
            // Cancel timeout task
            timeoutTask.cancel()
            
            DispatchQueue.main.async {
                // Clear connecting state
                self?.isConnecting = false
                
                if let error = error {
                    print("❌ [CHAT] Connection failed: \(error.localizedDescription)")
                    print("   Error details: \(error)")
                    self?.isConnected = false
                    self?.connectionError = "Connection failed: \(error.localizedDescription)"
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
            // Clear the client and API key - will be recreated on next connection
            chatClient = nil
            apiKey = nil
            print("✅ [CHAT] Chat client reset and data cleared")
        }
    }
}
