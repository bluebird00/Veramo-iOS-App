//
//  QuoteStatusService.swift
//  Veramo App
//
//  Service for checking quote/payment status using the quote-public endpoint
//

import Foundation

// MARK: - Payment Status Models

struct PaymentStatusResponse: Codable {
    let success: Bool
    let quoteStatus: String?
    let paymentStatus: String?
    let checkoutUrl: String?  // Only present if payment status is "open"
    let error: String?
}

enum PaymentStatus: String {
    case open = "open"           // Awaiting customer action (includes checkoutUrl for retry)
    case pending = "pending"     // Processing
    case paid = "paid"           // Success
    case failed = "failed"       // Payment failed
    case canceled = "canceled"   // Customer canceled
    case expired = "expired"     // Payment window expired
    case unknown = "unknown"     // Status could not be determined
    
    var isComplete: Bool {
        switch self {
        case .paid:
            return true
        case .failed, .canceled, .expired:
            return true
        case .open:
            // Open status means payment is awaiting customer action
            // Stop polling so user can see retry button
            return true
        default:
            return false
        }
    }
    
    var isSuccessful: Bool {
        return self == .paid
    }
    
    var canRetry: Bool {
        return self == .open
    }
}

// MARK: - Payment Status Error Types

enum PaymentStatusError: Error, LocalizedError {
    case invalidURL
    case invalidToken
    case networkError(Error)
    case decodingError
    case serverError(String)
    case paymentNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid payment status API URL"
        case .invalidToken:
            return "Invalid quote token"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to parse payment status response"
        case .serverError(let message):
            return message
        case .paymentNotFound:
            return "Payment not found"
        }
    }
}

// MARK: - Payment Status Service

class QuoteStatusService {
    static let shared = QuoteStatusService()
    
    private let baseURL = "https://veramo.ch/.netlify/functions"
    
    private init() {}
    
    /// Check the payment status using the app-payment-status endpoint
    /// - Parameter quoteToken: The quoteToken returned from app-book
    /// - Returns: PaymentStatusResponse with current status
    func checkPaymentStatus(quoteToken: String) async throws -> PaymentStatusResponse {
        guard !quoteToken.isEmpty else {
            throw PaymentStatusError.invalidToken
        }
        
        // Construct URL with token parameter
        guard let url = URL(string: "\(baseURL)/app-payment-status?token=\(quoteToken)") else {
            throw PaymentStatusError.invalidURL
        }
        
        // Configure HTTP request (no authentication needed for this endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("💳 PAYMENT STATUS CHECK")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🌐 URL: \(url.absoluteString)")
        print("🎫 Token: \(String(quoteToken.prefix(20)))...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                throw PaymentStatusError.networkError(NSError(domain: "", code: -1))
            }
            
            print("📊 Status Code: \(httpResponse.statusCode)")
            
            // Pretty print the JSON response
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                print("\n📄 Response Body:")
                print(prettyString)
            }
            
            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                let statusResponse = try decoder.decode(PaymentStatusResponse.self, from: data)
                
                guard statusResponse.success else {
                    let errorMsg = statusResponse.error ?? "Failed to get payment status"
                    print("❌ Server error: \(errorMsg)")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                    throw PaymentStatusError.serverError(errorMsg)
                }
                
                print("\n✅ PAYMENT STATUS RETRIEVED")
                print("   • Quote Status: \(statusResponse.quoteStatus ?? "N/A")")
                print("   • Payment Status: \(statusResponse.paymentStatus ?? "N/A")")
                if let checkoutUrl = statusResponse.checkoutUrl {
                    print("   • Checkout URL available: \(checkoutUrl.prefix(50))...")
                }
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                
                return statusResponse
                
            case 404:
                print("❌ Payment not found")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                throw PaymentStatusError.paymentNotFound
                
            default:
                let errorMsg = "Server returned status code: \(httpResponse.statusCode)"
                print("❌ \(errorMsg)")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                throw PaymentStatusError.serverError(errorMsg)
            }
            
        } catch let error as PaymentStatusError {
            throw error
        } catch let error as DecodingError {
            print("❌ Decoding error: \(error)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            throw PaymentStatusError.decodingError
        } catch {
            print("❌ Network error: \(error.localizedDescription)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            throw PaymentStatusError.networkError(error)
        }
    }
    
    /// Poll the payment status until it's complete or timeout is reached
    /// - Parameters:
    ///   - quoteToken: The quoteToken returned from app-book
    ///   - maxAttempts: Maximum number of polling attempts (default: 20)
    ///   - delaySeconds: Delay between polling attempts in seconds (default: 3)
    /// - Returns: Final PaymentStatusResponse
    func pollPaymentStatus(
        quoteToken: String,
        maxAttempts: Int = 20,
        delaySeconds: UInt64 = 3
    ) async throws -> PaymentStatusResponse {
        
        print("🔄 Starting payment status polling (max \(maxAttempts) attempts, \(delaySeconds)s interval)")
        
        for attempt in 1...maxAttempts {
            print("📊 Polling attempt \(attempt)/\(maxAttempts)")
            
            do {
                let statusResponse = try await checkPaymentStatus(quoteToken: quoteToken)
                
                // Parse the payment status
                let paymentStatus = PaymentStatus(rawValue: statusResponse.paymentStatus ?? "unknown") ?? .unknown
                
                // If payment is complete (success or failure), return immediately
                if paymentStatus.isComplete {
                    print("✅ Final payment status received: \(paymentStatus.rawValue)")
                    return statusResponse
                }
                
                // Still processing, wait before next attempt
                if attempt < maxAttempts {
                    print("⏳ Payment status: \(paymentStatus.rawValue), waiting \(delaySeconds)s before next check...")
                    try await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
                }
                
            } catch {
                // If this is not the last attempt, wait and retry
                if attempt < maxAttempts {
                    print("⚠️ Error checking status (attempt \(attempt)), retrying...")
                    try await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
                } else {
                    // Last attempt failed, throw the error
                    throw error
                }
            }
        }
        
        // If we exhausted all attempts, return the last known status
        print("⏱️ Polling timeout reached - payment may still be processing")
        let finalStatus = try await checkPaymentStatus(quoteToken: quoteToken)
        return finalStatus
    }
}
