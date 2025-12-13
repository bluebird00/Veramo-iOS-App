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
    case unauthorized  // 401 - Session expired
    
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
        case .unauthorized:
            return "Your session has expired. Please log in again."
        }
    }
}

struct AuthenticatedCustomer: Codable {
    let id: Int
    let name: String?  // Optional - null for new users
    let email: String?  // Optional - null for new users
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
    let language: String?  // Optional language code (e.g., "de", "en", "fr", "it")
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
    let isNewUser: Bool?
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
        } catch {
            throw AuthError.networkError(error)
        }
    }
    
    // MARK: - SMS Code Authentication
    
    /// Sends a verification code to the user's phone via SMS
    /// - Parameters:
    ///   - phone: The phone number in E.164 format (e.g., "+41791234567")
    ///   - language: Optional language code (e.g., "de", "en", "fr", "it"). If nil, uses device language or defaults to "de"
    func requestSMSCode(phone: String, language: String? = nil) async throws -> SMSCodeSendResponse {
        print("📱 [SMS-SEND] Starting SMS code request")
        print("📱 [SMS-SEND] Phone number: \(phone)")
        
        // Determine language to use
        let smsLanguage = language ?? Locale.current.language.languageCode?.identifier ?? "de"
        print("📱 [SMS-SEND] Language: \(smsLanguage)")
        
        guard let url = URL(string: "\(baseURL)/sms-code-send") else {
            print("❌ [SMS-SEND] Invalid URL")
            throw AuthError.invalidURL
        }
        
        print("🌐 [SMS-SEND] URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = SMSCodeRequest(phone: phone, language: smsLanguage)
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
    
    /// Verifies an SMS code and returns the authenticated customer, session token, and whether the user is new
    func verifySMSCode(phone: String, code: String) async throws -> (customer: AuthenticatedCustomer, sessionToken: String, isNewUser: Bool) {
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
                let isNewUser = verifyResponse.isNewUser ?? false
                print("✅ [SMS-VERIFY] Success!")
                print("✅ [SMS-VERIFY] Customer: \(customer.name ?? "nil") (ID: \(customer.id))")
                print("✅ [SMS-VERIFY] Email: \(customer.email ?? "nil")")
                print("✅ [SMS-VERIFY] Phone: \(customer.phone ?? "N/A")")
                print("✅ [SMS-VERIFY] Is new user: \(isNewUser)")
                print("✅ [SMS-VERIFY] Session token: \(String(sessionToken.prefix(20)))...")
                return (customer: customer, sessionToken: sessionToken, isNewUser: isNewUser)
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
    
    // MARK: - Profile Management
    
    /// Retrieves the current user's profile
    func getProfile(sessionToken: String) async throws -> AuthenticatedCustomer {
        print("👤 [PROFILE-GET] Starting profile retrieval")
        
        guard let url = URL(string: "\(baseURL)/app-profile") else {
            print("❌ [PROFILE-GET] Invalid URL")
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        
        do {
            print("🚀 [PROFILE-GET] Sending request...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [PROFILE-GET] Invalid HTTP response")
                throw AuthError.networkError(NSError(domain: "", code: -1))
            }
            
            print("📥 [PROFILE-GET] Response status code: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 [PROFILE-GET] Response body: \(responseString)")
            }
            
            if httpResponse.statusCode == 401 {
                print("❌ [PROFILE-GET] Unauthorized (401)")
                throw AuthError.unauthorized
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ [PROFILE-GET] Server error: \(httpResponse.statusCode)")
                throw AuthError.serverError("Server returned status code: \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            let profileResponse = try decoder.decode(ProfileResponse.self, from: data)
            
            if profileResponse.success, let customer = profileResponse.customer {
                print("✅ [PROFILE-GET] Success!")
                print("✅ [PROFILE-GET] Customer: \(customer.name ?? "nil") (ID: \(customer.id))")
                return customer
            } else {
                throw AuthError.serverError("Failed to retrieve profile")
            }
        } catch let error as AuthError {
            print("❌ [PROFILE-GET] Auth error: \(error.localizedDescription)")
            throw error
        } catch let error as DecodingError {
            print("❌ [PROFILE-GET] Decoding error: \(error)")
            throw AuthError.decodingError
        } catch {
            print("❌ [PROFILE-GET] Network error: \(error.localizedDescription)")
            throw AuthError.networkError(error)
        }
    }
    
    /// Updates the current user's profile
    func updateProfile(sessionToken: String, name: String?, email: String?) async throws -> AuthenticatedCustomer {
        print("✏️ [PROFILE-UPDATE] Starting profile update")
        print("✏️ [PROFILE-UPDATE] Name: \(name ?? "nil")")
        print("✏️ [PROFILE-UPDATE] Email: \(email ?? "nil")")
        
        guard let url = URL(string: "\(baseURL)/app-profile") else {
            print("❌ [PROFILE-UPDATE] Invalid URL")
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ProfileUpdateRequest(name: name, email: email)
        request.httpBody = try JSONEncoder().encode(body)
        
        if let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📦 [PROFILE-UPDATE] Request body: \(bodyString)")
        }
        
        do {
            print("🚀 [PROFILE-UPDATE] Sending request...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [PROFILE-UPDATE] Invalid HTTP response")
                throw AuthError.networkError(NSError(domain: "", code: -1))
            }
            
            print("📥 [PROFILE-UPDATE] Response status code: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 [PROFILE-UPDATE] Response body: \(responseString)")
            }
            
            if httpResponse.statusCode == 401 {
                print("❌ [PROFILE-UPDATE] Unauthorized (401)")
                throw AuthError.unauthorized
            }
            
            if httpResponse.statusCode == 409 {
                print("❌ [PROFILE-UPDATE] Email already in use (409)")
                throw AuthError.serverError("Email already in use")
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ [PROFILE-UPDATE] Server error: \(httpResponse.statusCode)")
                throw AuthError.serverError("Server returned status code: \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            let profileResponse = try decoder.decode(ProfileResponse.self, from: data)
            
            if profileResponse.success, let customer = profileResponse.customer {
                print("✅ [PROFILE-UPDATE] Success!")
                print("✅ [PROFILE-UPDATE] Updated customer: \(customer.name ?? "nil") (ID: \(customer.id))")
                
                // Update local storage
                AuthenticationManager.shared.currentCustomer = customer
                
                return customer
            } else {
                throw AuthError.serverError("Failed to update profile")
            }
        } catch let error as AuthError {
            print("❌ [PROFILE-UPDATE] Auth error: \(error.localizedDescription)")
            throw error
        } catch let error as DecodingError {
            print("❌ [PROFILE-UPDATE] Decoding error: \(error)")
            throw AuthError.decodingError
        } catch {
            print("❌ [PROFILE-UPDATE] Network error: \(error.localizedDescription)")
            throw AuthError.networkError(error)
        }
    }
    
}

// MARK: - Profile API Models

struct ProfileResponse: Codable {
    let success: Bool
    let customer: AuthenticatedCustomer?
}

struct ProfileUpdateRequest: Codable {
    let name: String?
    let email: String?
}
