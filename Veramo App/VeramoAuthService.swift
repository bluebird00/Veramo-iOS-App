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

// MARK: - SMS Code Models

struct SMSCodeRequest: Codable {
    let phone: String
}

struct SMSCodeSendResponse: Codable {
    let success: Bool
    let message: String
}

struct SMSCodeVerifyRequest: Codable {
    let phone: String
    let code: String
}

struct SMSCodeVerifyResponse: Codable {
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
    
    // MARK: - SMS Code Authentication
    
    /// Sends a verification code to the user's phone via SMS
    func requestSMSCode(phone: String) async throws -> SMSCodeSendResponse {
        print("📱 [SMS-SEND] Starting SMS code request")
        print("📱 [SMS-SEND] Phone number: \(phone)")
        
        guard let url = URL(string: "\(baseURL)/sms-code-send") else {
            print("❌ [SMS-SEND] Invalid URL")
            throw AuthError.invalidURL
        }
        
        print("🌐 [SMS-SEND] URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = SMSCodeRequest(phone: phone)
        request.httpBody = try JSONEncoder().encode(body)
        
        if let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📦 [SMS-SEND] Request body: \(bodyString)")
        }
        
        do {
            print("🚀 [SMS-SEND] Sending request...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [SMS-SEND] Invalid HTTP response")
                throw AuthError.networkError(NSError(domain: "", code: -1))
            }
            
            print("📥 [SMS-SEND] Response status code: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 [SMS-SEND] Response body: \(responseString)")
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ [SMS-SEND] Server error: \(httpResponse.statusCode)")
                throw AuthError.serverError("Server returned status code: \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            let sendResponse = try decoder.decode(SMSCodeSendResponse.self, from: data)
            
            print("✅ [SMS-SEND] Success: \(sendResponse.message)")
            return sendResponse
        } catch let error as AuthError {
            print("❌ [SMS-SEND] Auth error: \(error.localizedDescription)")
            throw error
        } catch let error as DecodingError {
            print("❌ [SMS-SEND] Decoding error: \(error)")
            throw AuthError.decodingError
        } catch {
            print("❌ [SMS-SEND] Network error: \(error.localizedDescription)")
            throw AuthError.networkError(error)
        }
    }
    
    /// Verifies an SMS code and returns the authenticated customer and session token
    func verifySMSCode(phone: String, code: String) async throws -> (customer: AuthenticatedCustomer, sessionToken: String) {
        print("🔐 [SMS-VERIFY] Starting SMS code verification")
        print("🔐 [SMS-VERIFY] Phone number: \(phone)")
        print("🔐 [SMS-VERIFY] Code: \(code)")
        
        guard let url = URL(string: "\(baseURL)/sms-code-verify") else {
            print("❌ [SMS-VERIFY] Invalid URL")
            throw AuthError.invalidURL
        }
        
        print("🌐 [SMS-VERIFY] URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = SMSCodeVerifyRequest(phone: phone, code: code)
        request.httpBody = try JSONEncoder().encode(body)
        
        if let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📦 [SMS-VERIFY] Request body: \(bodyString)")
        }
        
        do {
            print("🚀 [SMS-VERIFY] Sending request...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [SMS-VERIFY] Invalid HTTP response")
                throw AuthError.networkError(NSError(domain: "", code: -1))
            }
            
            print("📥 [SMS-VERIFY] Response status code: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 [SMS-VERIFY] Response body: \(responseString)")
            }
            
            // Handle 401 - Invalid or expired code
            if httpResponse.statusCode == 401 {
                print("❌ [SMS-VERIFY] Invalid or expired code (401)")
                throw AuthError.invalidToken
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ [SMS-VERIFY] Server error: \(httpResponse.statusCode)")
                throw AuthError.serverError("Server returned status code: \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            let verifyResponse = try decoder.decode(SMSCodeVerifyResponse.self, from: data)
            
            if verifyResponse.success,
               let customer = verifyResponse.customer,
               let sessionToken = verifyResponse.sessionToken {
                print("✅ [SMS-VERIFY] Success!")
                print("✅ [SMS-VERIFY] Customer: \(customer.name) (ID: \(customer.id))")
                print("✅ [SMS-VERIFY] Email: \(customer.email)")
                print("✅ [SMS-VERIFY] Phone: \(customer.phone ?? "N/A")")
                print("✅ [SMS-VERIFY] Session token: \(String(sessionToken.prefix(20)))...")
                return (customer: customer, sessionToken: sessionToken)
            } else {
                let errorMsg = verifyResponse.error ?? "Invalid verification code"
                print("❌ [SMS-VERIFY] Verification failed: \(errorMsg)")
                throw AuthError.serverError(errorMsg)
            }
        } catch let error as AuthError {
            print("❌ [SMS-VERIFY] Auth error: \(error.localizedDescription)")
            throw error
        } catch let error as DecodingError {
            print("❌ [SMS-VERIFY] Decoding error: \(error)")
            throw AuthError.decodingError
        } catch {
            print("❌ [SMS-VERIFY] Network error: \(error.localizedDescription)")
            throw AuthError.networkError(error)
        }
    }
    
}
