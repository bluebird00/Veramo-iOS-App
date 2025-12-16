//
//  BookingConfirmedView.swift
//  Veramo App
//
//  Booking confirmation page shown after payment redirect
//  Checks payment status via app-payment-status endpoint
//

import SwiftUI
import SafariServices

struct BookingConfirmedView: View {
    let reference: String
    let quoteToken: String?
    @Binding var selectedTab: MainTabView.Tab
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            BookingConfirmedViewContent(
                reference: reference,
                quoteToken: quoteToken,
                onSeeTrips: {
                    selectedTab = .trips
                    dismiss()
                },
                onDismiss: {
                    dismiss()
                }
            )
        }
    }
}

// MARK: - Content View (reusable)

struct BookingConfirmedViewContent: View {
    let reference: String
    let quoteToken: String?
    var onSeeTrips: (() -> Void)? = nil
    var onDismiss: () -> Void
    
    // Payment status state
    @State private var paymentStatus: PaymentStatus = .pending
    @State private var isCheckingStatus = true
    @State private var statusCheckError: String?
    @State private var paymentStatusResponse: PaymentStatusResponse?
    @State private var checkoutUrl: String?
    @State private var showPaymentSafari = false
    @State private var showTripTracking = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Status Icon
            statusIcon
                .font(.system(size: 100))
                .symbolEffect(.bounce, value: paymentStatus)
            
            // Title
            VStack(spacing: 8) {
                Text(titleText)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Reference: \(reference)", comment: "Booking reference number label")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                
                if isCheckingStatus {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Checking payment status...", comment: "Payment status check in progress message")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
            
            // Status-specific content
            statusContent
            
            Spacer()
            
            // Action Buttons
            actionButtons
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled((paymentStatus == .pending && isCheckingStatus))
        .task {
            await checkPaymentStatus()
        }
        .onAppear {
            print("📱 [VIEW] BookingConfirmedViewContent appeared")
            print("📱 [VIEW] Reference: \(reference)")
            print("📱 [VIEW] Quote Token: \(quoteToken ?? "N/A")")
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var statusIcon: some View {
        switch paymentStatus {
        case .paid:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .pending, .open:
            Image(systemName: "clock.fill")
                .foregroundStyle(.orange)
        case .failed, .canceled, .expired:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        case .unknown:
            Image(systemName: "questionmark.circle.fill")
                .foregroundStyle(.gray)
        }
    }
    
    private var titleText: String {
        switch paymentStatus {
        case .paid:
            return String(localized: "Booking Confirmed!", comment: "Title shown when booking payment is successful")
        case .pending, .open:
            return String(localized: "Payment Pending", comment: "Title shown when payment is still processing or awaiting action")
        case .failed:
            return String(localized: "Payment Failed", comment: "Title shown when payment failed")
        case .canceled:
            return String(localized: "Payment Canceled", comment: "Title shown when payment was canceled by user")
        case .expired:
            return String(localized: "Payment Expired", comment: "Title shown when payment window expired")
        case .unknown:
            return String(localized: "Status Unknown", comment: "Title shown when payment status cannot be determined")
        }
    }
    
    private var navigationTitle: String {
        switch paymentStatus {
        case .paid:
            return String(localized: "Success", comment: "Navigation title for successful payment")
        case .pending, .open:
            return String(localized: "Pending", comment: "Navigation title for pending payment")
        case .failed:
            return String(localized: "Failed", comment: "Navigation title for failed payment")
        case .canceled:
            return String(localized: "Canceled", comment: "Navigation title for canceled payment")
        case .expired:
            return String(localized: "Expired", comment: "Navigation title for expired payment")
        case .unknown:
            return String(localized: "Status", comment: "Navigation title for unknown payment status")
        }
    }
    
    @ViewBuilder
    private var statusContent: some View {
        switch paymentStatus {
        case .paid:
            successContent
        case .pending, .open:
            pendingContent
        case .failed, .canceled, .expired:
            failedContent
        case .unknown:
            unknownContent
        }
    }
    
    private var successContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's Next?", comment: "Section title for next steps after successful booking")
                .font(.headline)
                .foregroundStyle(.primary)
            
            InfoRow(
                icon: "bell.fill",
                text: String(localized: "You'll receive notifications about your ride", comment: "Information about receiving notifications")
            )
            
            
            InfoRow(
                icon: "questionmark.circle.fill",
                text: String(localized: "Need help? Contact support anytime", comment: "Information about support availability")
            )
            
            
            
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showTripTracking) {
            TripTrackingView(reference: reference)
        }
    }
    
    private var pendingContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(paymentStatus == .open 
                ? String(localized: "Payment Awaiting Action", comment: "Title shown when payment requires user action")
                : String(localized: "Payment In Progress", comment: "Title shown when payment is processing"))
                .font(.headline)
                .foregroundStyle(.primary)
            
            if paymentStatus == .open {
                InfoRow(
                    icon: "creditcard",
                    text: String(localized: "Payment requires your action to complete", comment: "Message explaining payment needs user action")
                )
                
                
                
            } else {
                InfoRow(
                    icon: "hourglass",
                    text: String(localized: "Your payment is being processed", comment: "Message explaining payment is processing")
                )
                
                InfoRow(
                    icon: "checkmark.circle",
                    text: String(localized: "This usually takes a few seconds", comment: "Message about typical processing time")
                )
            }
            
            
            if let error = statusCheckError {
                Divider()
                    .padding(.vertical, 4)
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var failedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(failedContentTitle)
                .font(.headline)
                .foregroundStyle(.primary)
            
            InfoRow(
                icon: failedContentIcon,
                text: failedContentMessage
            )
            
            InfoRow(
                icon: "arrow.clockwise",
                text: String(localized: "Please create a new booking to try again", comment: "Message prompting user to create new booking")
            )
            
            InfoRow(
                icon: "creditcard",
                text: String(localized: "You have not been charged", comment: "Message confirming no charge was made")
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var failedContentTitle: String {
        switch paymentStatus {
        case .failed:
            return String(localized: "Payment Failed", comment: "Section title for failed payment")
        case .canceled:
            return String(localized: "Payment Canceled", comment: "Section title for canceled payment")
        case .expired:
            return String(localized: "Payment Expired", comment: "Section title for expired payment")
        default:
            return String(localized: "Payment Not Completed", comment: "Section title for incomplete payment")
        }
    }
    
    private var failedContentIcon: String {
        switch paymentStatus {
        case .failed:
            return "xmark.circle"
        case .canceled:
            return "xmark.circle"
        case .expired:
            return "clock.badge.xmark"
        default:
            return "exclamationmark.triangle"
        }
    }
    
    private var failedContentMessage: String {
        switch paymentStatus {
        case .failed:
            return String(localized: "The payment could not be processed", comment: "Message explaining payment processing failure")
        case .canceled:
            return String(localized: "You canceled the payment", comment: "Message explaining user canceled payment")
        case .expired:
            return String(localized: "The payment window has expired", comment: "Message explaining payment time expired")
        default:
            return String(localized: "Payment was not completed", comment: "Generic message for incomplete payment")
        }
    }
    
    private var unknownContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Unable to Verify Status", comment: "Section title when payment status cannot be verified")
                .font(.headline)
                .foregroundStyle(.primary)
            
            InfoRow(
                icon: "wifi.slash",
                text: String(localized: "Could not check payment status", comment: "Message explaining status check failure")
            )
            
            
            InfoRow(
                icon: "questionmark.circle",
                text: String(localized: "Contact support if you need assistance", comment: "Message prompting user to contact support")
            )
            
            if let error = statusCheckError {
                Divider()
                    .padding(.vertical, 4)
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Button(action: {
                Task {
                    await checkPaymentStatus()
                }
            }) {
                Label(String(localized: "Check Again", comment: "Button to retry checking payment status"), systemImage: "arrow.clockwise")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Retry payment button for "open" status
            if paymentStatus == .open {
                Button {
                    showPaymentSafari = true
                } label: {
                    Label(String(localized: "Complete Payment", comment: "Button to complete pending payment"), systemImage: "creditcard")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Primary action button
            if paymentStatus == .paid {
                // Show trips button for successful payments
                if let onSeeTrips = onSeeTrips {
                    Button {
                        onSeeTrips()
                    } label: {
                        Label(String(localized: "See Upcoming Trips", comment: "Button to view upcoming trips"), systemImage: "calendar")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            } else if paymentStatus.isComplete && paymentStatus != .paid {
                // Show book again button for failed/canceled/expired payments
                Button {
                    onDismiss()
                } label: {
                    Label(String(localized: "Create New Booking", comment: "Button to create a new booking"), systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Secondary dismiss button
            Button {
                onDismiss()
            } label: {
                Text(paymentStatus == .paid 
                    ? String(localized: "Done", comment: "Button to close confirmation screen after success")
                    : String(localized: "Close", comment: "Button to close confirmation screen"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(paymentStatus == .pending && isCheckingStatus)
        }
        .fullScreenCover(isPresented: $showPaymentSafari) {
            // Called when Safari is dismissed - check payment status again
            print("💳 [PAYMENT] Payment Safari dismissed, rechecking status...")
            Task {
                await checkPaymentStatus()
            }
        } content: {
            if let urlString = checkoutUrl, let url = URL(string: urlString) {
                SafariView(url: url) {
                    // Dismiss handler
                    showPaymentSafari = false
                }
                .ignoresSafeArea()
            }
        }
    }
    
    // MARK: - Payment Status Check
    
    private func checkPaymentStatus() async {
        guard let token = quoteToken, !token.isEmpty else {
            print("⚠️ [PAYMENT] No quote token available - cannot verify payment")
            // Without a token, we cannot verify payment status
            // This is an error state - don't assume success
            statusCheckError = "Unable to verify payment status. Please contact support."
            paymentStatus = .unknown
            isCheckingStatus = false
            return
        }
        
        isCheckingStatus = true
        statusCheckError = nil
        
        do {
            print("🔍 [PAYMENT] Checking payment status with token...")
            
            // Poll for status (max 20 attempts, 3 seconds between checks)
            let response = try await QuoteStatusService.shared.pollPaymentStatus(
                quoteToken: token,
                maxAttempts: 20,
                delaySeconds: 3
            )
            
            paymentStatusResponse = response
            let rawStatus = response.paymentStatus ?? "unknown"
            paymentStatus = PaymentStatus(rawValue: rawStatus) ?? .unknown
            checkoutUrl = response.checkoutUrl
            
            print("✅ [PAYMENT] Status check complete:")
            print("   • Raw payment status: \(rawStatus)")
            print("   • Parsed PaymentStatus: \(paymentStatus.rawValue)")
            print("   • Checkout URL: \(checkoutUrl ?? "none")")
            print("   • isComplete: \(paymentStatus.isComplete)")
            print("   • canRetry: \(paymentStatus.canRetry)")
            
            // Track booking confirmed in AppsFlyer when payment is successful
            if paymentStatus == .paid,
               let priceCents = response.priceCents,
               let pickup = response.pickupDescription,
               let destination = response.destinationDescription,
               let vehicleClass = response.vehicleClass {
                
                print("📊 [AppsFlyer] Tracking ride_booking_confirmed with payment data")
                
                AppsFlyerEvents.shared.trackRideBookingConfirmedDetailed(
                    reference: reference,
                    priceCents: priceCents,
                    pickup: pickup,
                    destination: destination,
                    vehicleClass: vehicleClass,
                    passengers: response.passengers ?? 1,
                    distance: nil, // Not provided by payment status endpoint
                    paymentMethod: response.paymentMethod
                )
            }
            
        } catch {
            print("❌ [PAYMENT] Status check failed: \(error.localizedDescription)")
            statusCheckError = error.localizedDescription
            paymentStatus = .unknown
        }
        
        isCheckingStatus = false
    }
    
    private func formatPrice(_ cents: Int) -> String {
        let chf = Double(cents) / 100.0
        return String(format: "CHF %.2f", chf)
    }
}

// MARK: - Supporting Views

private struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
             
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    BookingConfirmedView(
        reference: "VRM-1234-5678",
        quoteToken: "test-token-123",
        selectedTab: .constant(.home)
    )
}
