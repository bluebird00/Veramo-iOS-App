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
    
    private let apiKey = "j46xbwqsrzsk"
    
    private init() {
        setupChatClient()
    }
    
    private func setupChatClient() {
        var config = ChatClientConfig(apiKey: .init(apiKey))
        config.isLocalStorageEnabled = true
        
        chatClient = ChatClient(config: config)
        
        print("✅ Stream Chat client initialized successfully")
    }
    
    func connectUser(customer: AuthenticatedCustomer, token: String) {
        guard let chatClient = chatClient else {
            connectionError = "Chat client not initialized"
            return
        }
        
        let userInfo = UserInfo(
            id: "customer-\(customer.id)",
            name: customer.name,
            imageURL: nil
        )
        
        chatClient.connectUser(userInfo: userInfo, token: .init(stringLiteral: token)) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isConnected = false
                    self?.connectionError = error.localizedDescription
                    print("❌ Stream Chat connection error: \(error)")
                } else {
                    self?.isConnected = true
                    self?.connectionError = nil
                    print("✅ Stream Chat connected successfully")
                }
            }
        }
    }
    
    func disconnect() {
        chatClient?.disconnect()
        isConnected = false
    }
}
