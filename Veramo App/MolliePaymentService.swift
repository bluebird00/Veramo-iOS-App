//
//  MolliePaymentService.swift
//  Veramo App
//
//  Created by rentamac on 12/9/25.
//

import Foundation
import SafariServices
import UIKit
import SwiftUI

enum MolliePaymentError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError
    case serverError(String)
    case paymentFailed
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid payment URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to parse payment response"
        case .serverError(let message):
            return message
        case .paymentFailed:
            return "Payment failed. Please try again."
        case .cancelled:
            return "Payment was cancelled"
        }
    }
}

struct MolliePaymentRequest: Codable {
    let amount: Int  // Amount in cents
    let description: String
    let redirectUrl: String
    let webhookUrl: String?
    let metadata: [String: String]?
}

struct MolliePaymentResponse: Codable {
    let success: Bool
    let paymentId: String?
    let checkoutUrl: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case paymentId = "payment_id"
        case checkoutUrl = "checkout_url"
        case error
    }
}

struct MolliePaymentStatus: Codable {
    let status: String  // paid, open, pending, failed, canceled, expired
    let paymentId: String
    
    enum CodingKeys: String, CodingKey {
        case status
        case paymentId = "payment_id"
    }
}

class MolliePaymentService {
    static let shared = MolliePaymentService()
    
    private let baseURL = "https://veramo.ch/.netlify/functions"
    
    private init() {}
    
    /// Create a payment and get checkout URL
    func createPayment(
        amount: Int,  // Amount in cents
        description: String,
        sessionToken: String,
        metadata: [String: String]? = nil
    ) async throws -> (paymentId: String, checkoutUrl: String) {
        
        guard let url = URL(string: "\(baseURL)/mollie-create-payment") else {
            throw MolliePaymentError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        
        let paymentRequest = MolliePaymentRequest(
            amount: amount,
            description: description,
            redirectUrl: "veramo://payment-return",
            webhookUrl: nil,  // Backend will use its own webhook URL
            metadata: metadata
        )
        
        request.httpBody = try? JSONEncoder().encode(paymentRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MolliePaymentError.serverError("Invalid response")
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let paymentResponse = try? JSONDecoder().decode(MolliePaymentResponse.self, from: data) else {
                    throw MolliePaymentError.decodingError
                }
                
                guard paymentResponse.success,
                      let paymentId = paymentResponse.paymentId,
                      let checkoutUrl = paymentResponse.checkoutUrl else {
                    throw MolliePaymentError.serverError(paymentResponse.error ?? "Payment creation failed")
                }
                
                print("✅ Payment created: \(paymentId)")
                return (paymentId, checkoutUrl)
                
            case 401:
                throw MolliePaymentError.serverError("Authentication failed")
                
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw MolliePaymentError.serverError("Server error (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
        } catch let error as MolliePaymentError {
            throw error
        } catch {
            throw MolliePaymentError.networkError(error)
        }
    }
    
    /// Check payment status
    func checkPaymentStatus(paymentId: String, sessionToken: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/mollie-payment-status?payment_id=\(paymentId)") else {
            throw MolliePaymentError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw MolliePaymentError.serverError("Failed to check payment status")
            }
            
            guard let statusResponse = try? JSONDecoder().decode(MolliePaymentStatus.self, from: data) else {
                throw MolliePaymentError.decodingError
            }
            
            print("💳 Payment status: \(statusResponse.status)")
            return statusResponse.status
            
        } catch let error as MolliePaymentError {
            throw error
        } catch {
            throw MolliePaymentError.networkError(error)
        }
    }
}

// MARK: - Safari View Controller Wrapper

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        
        let safari = SFSafariViewController(url: url, configuration: config)
        safari.delegate = context.coordinator
        safari.preferredControlTintColor = .black
        return safari
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let onDismiss: () -> Void
        
        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onDismiss()
        }
    }
}
