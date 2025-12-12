//
//  NetworkAuthenticationHandler.swift
//  Veramo App
//
//  Created by rentamac on 12/12/25.
//

import Foundation

/// Helper extension to check HTTP response status and handle authentication errors
extension URLResponse {
    
    /// Checks if the response indicates an authentication error (401 Unauthorized)
    var isUnauthorized: Bool {
        guard let httpResponse = self as? HTTPURLResponse else {
            return false
        }
        return httpResponse.statusCode == 401
    }
    
    /// Checks if the response is successful (2xx status code)
    var isSuccessful: Bool {
        guard let httpResponse = self as? HTTPURLResponse else {
            return false
        }
        return (200...299).contains(httpResponse.statusCode)
    }
    
    /// Returns the HTTP status code, or nil if not an HTTP response
    var httpStatusCode: Int? {
        guard let httpResponse = self as? HTTPURLResponse else {
            return nil
        }
        return httpResponse.statusCode
    }
}

/// Protocol for services that need to handle authentication errors
protocol AuthenticationErrorHandling {
    func handleAuthenticationError()
}

/// Notification name for authentication errors
extension Notification.Name {
    static let userDidBecomeUnauthenticated = Notification.Name("userDidBecomeUnauthenticated")
}

/// Helper class to manage authentication errors across the app
class NetworkAuthenticationHandler {
    static let shared = NetworkAuthenticationHandler()
    
    private init() {}
    
    /// Call this method when you receive a 401 response from any API
    func handleUnauthorizedResponse(endpoint: String? = nil) {
        let endpointInfo = endpoint.map { " from endpoint: \($0)" } ?? ""
        print("⚠️ [AUTH] 401 Unauthorized detected\(endpointInfo)")
        print("   • Time: \(Date())")
        print("   • Action: Posting userDidBecomeUnauthenticated notification")
        print("   • Next: App will log out user and show login screen")
        
        // Post a notification that other parts of the app can observe
        // The app will handle the actual logout via the notification observer
        NotificationCenter.default.post(name: .userDidBecomeUnauthenticated, object: nil)
        
        print("   ✅ Notification posted successfully")
    }
    
    /// Check response and handle authentication errors automatically
    func checkResponse(_ response: URLResponse, endpoint: String? = nil) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            return
        }
        
        if httpResponse.statusCode == 401 {
            handleUnauthorizedResponse(endpoint: endpoint)
            throw AuthError.unauthorized
        }
    }
}
