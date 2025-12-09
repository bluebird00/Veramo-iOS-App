//
//  VeramoAuthService.swift
//  Veramo App
//
//  Created by rentamac on 12/7/25.
//

import Foundation

enum AuthError: Error, LocalizedError {
    case invalidToken
    case invalidURL
    case networkError(Error)
    case decodingError
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "Invalid authentication token"
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to parse server response"
        case .serverError(let message):
            return message
        }
    }
}

struct AuthenticatedCustomer: Codable {
    let id: Int
    let name: String
    let email: String
    let phone: String?  // Optional phone number
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, phone
    }
}

// MARK: - Request Magic Link Models

struct MagicLinkRequest: Codable {
    let email: String
}

struct MagicLinkSendResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - Verify Magic Link Models

struct MagicLinkVerifyResponse: Codable {
    let success: Bool
    let sessionToken: String?
    let customer: AuthenticatedCustomer?
    let error: String?
}

class VeramoAuthService {
    static let shared = VeramoAuthService()
    
    private let baseURL = "https://veramo.ch/.netlify/functions"
    
    private init() {}
    
    // MARK: - Request Magic Link
    
    /// Sends a magic link to the user's email
    func requestMagicLink(email: String) async throws -> MagicLinkSendResponse {
        guard let url = URL(string: "\(baseURL)/magic-link-send") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = MagicLinkRequest(email: email)
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError(NSError(domain: "", code: -1))
            }
            
            guard httpResponse.statusCode == 200 else {
                throw AuthError.serverError("Server returned status code: \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(MagicLinkSendResponse.self, from: data)
        } catch let error as AuthError {
            throw error
        } catch let error as DecodingError {
            throw AuthError.decodingError
        } catch {
            throw AuthError.networkError(error)
        }
    }
    
    // MARK: - Verify Magic Link
    
    /// Verifies a magic link token and returns the authenticated customer and session token
    func verifyMagicLink(token: String) async throws -> (customer: AuthenticatedCustomer, sessionToken: String) {
        // Build URL with query parameter
        var components = URLComponents(string: "\(baseURL)/magic-link-verify")
        components?.queryItems = [URLQueryItem(name: "token", value: token)]
        
        guard let url = components?.url else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError(NSError(domain: "", code: -1))
            }
            
            // Handle 401 - Invalid or expired link
            if httpResponse.statusCode == 401 {
                throw AuthError.invalidToken
            }
            
            guard httpResponse.statusCode == 200 else {
                throw AuthError.serverError("Server returned status code: \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            let verifyResponse = try decoder.decode(MagicLinkVerifyResponse.self, from: data)
            
            if verifyResponse.success,
               let customer = verifyResponse.customer,
               let sessionToken = verifyResponse.sessionToken {
                return (customer: customer, sessionToken: sessionToken)
            } else {
                throw AuthError.serverError(verifyResponse.error ?? "Authentication failed")
            }
        } catch let error as AuthError {
            throw error
        } catch let error as DecodingError {
            throw AuthError.decodingError
        } catch {
            throw AuthError.networkError(error)
        }
    }
    
}
