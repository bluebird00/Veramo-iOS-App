//
//  StreamChatTokenService.swift
//  Veramo App
//
//  Created by rentamac on 12/9/25.
//

import Foundation

enum StreamChatTokenError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError
    case serverError(String)
    case noToken
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to parse server response"
        case .serverError(let message):
            return message
        case .noToken:
            return "No Stream token received from server"
        }
    }
}

struct StreamTokenResponse: Codable {
    let token: String
    let userId: String
    let apiKey: String
}

class StreamChatTokenService {
    static let shared = StreamChatTokenService()
    
    private let baseURL = "https://veramo.ch/.netlify/functions"
    
    private init() {}
    
    func fetchStreamToken(customerId: Int, sessionToken: String) async throws -> StreamTokenResponse {
        print("🔑 [STREAM TOKEN] Fetching token for customer \(customerId)...")
        
        // Build URL
        guard let url = URL(string: "\(baseURL)/stream-chat-token") else {
            throw StreamChatTokenError.invalidURL
        }
        
        // Create request with timeout
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15 // 15 second timeout
        
        // Request body
        let body = ["customer_id": customerId]
        request.httpBody = try? JSONEncoder().encode(body)
        
        do {
            // Make request
            let (data, response) = try await URLSession.shared.data(for: request)
            print("🔑 [STREAM TOKEN] Received response from server")
            
            // Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StreamChatTokenError.serverError("Invalid response from server")
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200:
                // Success - decode token
                guard let tokenResponse = try? JSONDecoder().decode(StreamTokenResponse.self, from: data) else {
                    throw StreamChatTokenError.decodingError
                }
                
                guard !tokenResponse.token.isEmpty else {
                    throw StreamChatTokenError.noToken
                }
                
                print("✅ Stream token fetched successfully")
                print("   User ID: \(tokenResponse.userId)")
                print("   API Key: \(tokenResponse.apiKey)")
                return tokenResponse
                
            case 401:
                throw StreamChatTokenError.serverError("Authentication failed")
                
            case 403:
                throw StreamChatTokenError.serverError("Access denied")
                
            case 404:
                throw StreamChatTokenError.serverError("Endpoint not found")
                
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw StreamChatTokenError.serverError("Server error (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
        } catch let error as StreamChatTokenError {
            throw error
        } catch {
            throw StreamChatTokenError.networkError(error)
        }
    }
}
