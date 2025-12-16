//
//  ChatView.swift
//  Veramo App
//
//  Created by rentamac on 12/9/25.
//

import SwiftUI
import Combine
import StreamChat
import StreamChatSwiftUI

struct ChatView: View {
    @StateObject private var chatManager = ChatManager.shared
    @State private var showLoginSheet = false
    @Environment(AppState.self) private var appState
    
    var body: some View {
        NavigationStack {
            Group {
                if !AuthenticationManager.shared.isAuthenticated {
                    // Show unauthenticated state
                    unauthenticatedView
                } else if chatManager.isConnected, let chatClient = chatManager.chatClient {
                    // Show chat interface
                    SimpleChatInterfaceView(chatClient: chatClient)
                } else if let error = chatManager.connectionError {
                    // Show error state
                    errorView(error: error)
                } else if chatManager.isConnecting {
                    // Show connecting state
                    loadingView
                } else {
                    // Show loading state (fetching token)
                    loadingView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Support Chat")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
        }
        .sheet(isPresented: $showLoginSheet) {
            SMSLoginView()
        }
        .onAppear {
            connectUserIfNeeded()
        }
        .onChange(of: appState.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                // User just logged in, try to connect to chat
                connectUserIfNeeded()
            } else {
                // User logged out, disconnect and reset chat
                Task {
                    await chatManager.resetAndClearData()
                }
            }
        }
    }
    
    private var unauthenticatedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "message.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.black)
            }
            
            // Title and description
            VStack(spacing: 12) {
                Text("Chat with Customer Support")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("chat.login.message", comment: "Message prompting users to log in before accessing customer support chat")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Login button
            Button {
                showLoginSheet = true
            } label: {
                Text("Log In")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.black, Color(.darkGray)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
            }
            .padding(.top, 32)
            
            Spacer()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Connecting to customer support...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Connection Error")
                .font(.headline)
            
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                connectUserIfNeeded()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private func connectUserIfNeeded() {
        // Don't attempt connection if not authenticated
        guard AuthenticationManager.shared.isAuthenticated else {
            return
        }
        
        // Don't attempt if already connecting
        guard !chatManager.isConnecting else {
            print("⏳ [CHAT VIEW] Connection already in progress, skipping...")
            return
        }
        
        // Try to connect with authenticated customer
        if let customer = AuthenticationManager.shared.currentCustomer,
           let sessionToken = AuthenticationManager.shared.sessionToken {
            
            let currentChatUserId = chatManager.chatClient?.currentUserId
            let newUserId = "customer-\(customer.id)"
            
            // Check if we're trying to connect a different user
            if currentChatUserId != nil && currentChatUserId != newUserId {
                print("⚠️ [CHAT] Detected user change from \(currentChatUserId ?? "nil") to \(newUserId)")
                // Disconnect the old user and reset
                Task {
                    await chatManager.resetAndClearData()
                    // Now connect the new user
                    await fetchAndConnectUser(customer: customer, sessionToken: sessionToken)
                }
            } else if chatManager.isConnected && currentChatUserId == newUserId {
                // Already connected as the correct user, nothing to do
                print("✅ [CHAT] Already connected as correct user: \(newUserId)")
            } else if !chatManager.isConnected {
                // Not connected (regardless of whether userId is set), so connect
                print("🔌 [CHAT] Not connected, initiating connection...")
                Task {
                    await fetchAndConnectUser(customer: customer, sessionToken: sessionToken)
                }
            } else {
                print("⏳ [CHAT] Unexpected state - currentUserId: \(currentChatUserId ?? "nil"), isConnected: \(chatManager.isConnected)")
            }
        }
    }
    
    private func fetchAndConnectUser(customer: AuthenticatedCustomer, sessionToken: String) async {
        do {
            let streamTokenResponse = try await StreamChatTokenService.shared.fetchStreamToken(
                customerId: customer.id,
                sessionToken: sessionToken
            )
            
            // Connect with proper authentication and API key from backend
            await MainActor.run {
                chatManager.connectUser(
                    customer: customer,
                    token: streamTokenResponse.token,
                    apiKey: streamTokenResponse.apiKey
                )
            }
        } catch {
            // Show error
            await MainActor.run {
                chatManager.connectionError = "Failed to connect to chat. Please try again."
            }
        }
    }
}

// Simple chat interface that doesn't rely on Stream's pre-built UI
struct SimpleChatInterfaceView: View {
    let chatClient: ChatClient
    @State private var showChat = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header info
            VStack(alignment: .leading, spacing: 8) {
                Text("How can we help?")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Our support team is here to assist you with any questions about your bookings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            
            // Start chat button
            Button {
                showChat = true
            } label: {
                HStack {
                    Image(systemName: "message.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            LinearGradient(
                                colors: [.black, Color(.darkGray)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chat with Support")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Get help with your bookings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .padding(.horizontal)
            .padding(.top)
            
            Spacer()
        }
        .sheet(isPresented: $showChat) {
            CustomChatChannelView(chatClient: chatClient)
        }
    }
}

// Custom chat channel view using ChatClient directly
struct CustomChatChannelView: View {
    let chatClient: ChatClient
    @StateObject private var channelViewModel: CustomChannelViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(chatClient: ChatClient) {
        self.chatClient = chatClient
        _channelViewModel = StateObject(wrappedValue: CustomChannelViewModel(chatClient: chatClient))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if channelViewModel.isLoading {
                    ProgressView("Loading chat...")
                } else if let error = channelViewModel.error {
                    VStack(spacing: 16) {
                        Text("Error loading chat")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            channelViewModel.loadChannel()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    // Messages list
                    ScrollView {
                        ScrollViewReader { proxy in
                            LazyVStack(spacing: 12) {
                                ForEach(channelViewModel.messages) { message in
                                    MessageRow(message: message, currentUserId: chatClient.currentUserId)
                                        .id(message.id)
                                }
                            }
                            .padding()
                            .onChange(of: channelViewModel.messages.count) { _, _ in
                                if let lastMessage = channelViewModel.messages.last {
                                    withAnimation {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Message input
                    HStack(spacing: 12) {
                        TextField("Type a message...", text: $channelViewModel.messageText)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            channelViewModel.sendMessage()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(channelViewModel.messageText.isEmpty ? .gray : .black)
                        }
                        .disabled(channelViewModel.messageText.isEmpty)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                }
            }
            .navigationTitle("Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            channelViewModel.loadChannel()
        }
    }
}

// Message row view
struct MessageRow: View {
    let message: ChatMessage
    let currentUserId: String?
    
    private var isCurrentUser: Bool {
        message.author.id == currentUserId
    }
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.author.name ?? "Unknown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isCurrentUser ? Color.black : Color(.systemGray5))
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isCurrentUser { Spacer() }
        }
    }
}

// View model to handle channel logic
@MainActor
class CustomChannelViewModel: ObservableObject {
    private let chatClient: ChatClient
    private var channelController: ChatChannelController?
    
    @Published var messages: [ChatMessage] = []
    @Published var messageText = ""
    @Published var isLoading = false
    @Published var error: String?
    
    init(chatClient: ChatClient) {
        self.chatClient = chatClient
    }
    
    func loadChannel() {
        guard let currentUserId = chatClient.currentUserId else {
            error = "User not connected"
            return
        }
        
        isLoading = true
        error = nil
        
        // Create unique support channel for this customer with veramo-admin
        let channelId = ChannelId(type: .messaging, id: "support-\(currentUserId)")
        
        // Track chat opened in AppsFlyer
        AppsFlyerEvents.shared.trackChatOpened(channelId: channelId.id)
        
        // Create channel with both customer and veramo-admin as members
        do {
            let channel = try chatClient.channelController(
                createChannelWithId: channelId,
                name: "Support Chat",
                members: [currentUserId, "veramo-admin"],
                isCurrentUserMember: true
            )
            
            channelController = channel
            
            // Set up delegate
            channelController?.delegate = self
            
            // Synchronize channel
            channelController?.synchronize { [weak self] syncError in
                DispatchQueue.main.async {
                    self?.isLoading = false
                   
                }
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                self?.error = "Failed to initialize chat channel"
            }
        }
    }
    
    private func loadMessages() {
        guard let channel = channelController?.channel else { return }
        // Reverse the order so oldest messages appear first (at top)
        messages = channel.latestMessages.reversed()
    }
    
    func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let text = messageText
        messageText = ""
        
        channelController?.createNewMessage(text: text) { result in
            
        }
    }
}

// Channel controller delegate
extension CustomChannelViewModel: ChatChannelControllerDelegate {
    func channelController(_ channelController: ChatChannelController, didUpdateMessages changes: [ListChange<ChatMessage>]) {
        loadMessages()
    }
}

#Preview {
    ChatView()
        .environment(AppState())
}
