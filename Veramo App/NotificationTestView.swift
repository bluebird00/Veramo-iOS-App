//
//  NotificationTestView.swift
//  Veramo App
//
//  Test view for triggering driver notifications during development
//

import SwiftUI

struct NotificationTestView: View {
    @State private var testReference = "VRM-TEST-\(Int.random(in: 1000...9999))"
    @State private var driverName = "Test Driver"
    @State private var selectedStatus: DriverStatus = .enRoute
    @State private var estimatedMinutes = 5
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Test Information") {
                    HStack {
                        Text("Reference:")
                        Spacer()
                        Text(testReference)
                            .foregroundStyle(.secondary)
                    }
                    
                    TextField("Driver Name", text: $driverName)
                }
                
                Section("Driver Status") {
                    Picker("Status", selection: $selectedStatus) {
                        ForEach([DriverStatus.enRoute, .arrived, .waitingForPickup, .pickupComplete, .droppingOff, .complete, .canceled], id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    
                    if selectedStatus == .enRoute || selectedStatus == .droppingOff {
                        Stepper("ETA: \(estimatedMinutes) min", value: $estimatedMinutes, in: 1...60)
                    }
                }
                
                Section("Test Notifications") {
                    Button {
                        sendDriverArrivedNotification()
                    } label: {
                        Label("Send Driver Arrived", systemImage: "bell.fill")
                    }
                    
                    Button {
                        sendStatusNotification()
                    } label: {
                        Label("Send Status Notification", systemImage: "bell.badge")
                    }
                }
                
                Section("Device Token") {
                    if let token = UserDefaults.standard.string(forKey: "deviceToken") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Device Token:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(token)
                                .font(.caption2)
                                .textSelection(.enabled)
                        }
                        
                        Button {
                            UIPasteboard.general.string = token
                            alertMessage = "Device token copied to clipboard!"
                            showAlert = true
                        } label: {
                            Label("Copy Token", systemImage: "doc.on.doc")
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("No device token registered")
                                .foregroundStyle(.orange)
                            
                            Text("This is normal if:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("• Running in iOS Simulator")
                                Text("• Notification permissions denied")
                                Text("• APNs hasn't responded yet")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            
                            Button {
                                // Trigger APNs registration
                                UIApplication.shared.registerForRemoteNotifications()
                                alertMessage = "Requesting device token from APNs..."
                                showAlert = true
                            } label: {
                                Label("Request Token Again", systemImage: "arrow.clockwise")
                            }
                            
                            Button {
                                // Open app settings
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Label("Open Notification Settings", systemImage: "gear")
                            }
                        }
                    }
                }
                
                Section("Authentication") {
                    if AuthenticationManager.shared.isAuthenticated {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Authenticated")
                                .foregroundStyle(.green)
                            if let customer = AuthenticationManager.shared.currentCustomer {
                                Text("Customer ID: \(customer.id)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let name = customer.name {
                                    Text("Name: \(name)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else {
                        Text("Not authenticated")
                            .foregroundStyle(.orange)
                    }
                }
                
                Section("Actions") {
                    Button {
                        generateNewReference()
                    } label: {
                        Label("Generate New Reference", systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationTitle("Test Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Success", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func sendDriverArrivedNotification() {
        PushNotificationService.shared.sendDriverArrivedNotification(
            reference: testReference,
            driverName: driverName
        )
        
        alertMessage = "Driver arrival notification sent for \(testReference)"
        showAlert = true
    }
    
    private func sendStatusNotification() {
        let minutes = (selectedStatus == .enRoute || selectedStatus == .droppingOff) ? estimatedMinutes : nil
        
        PushNotificationService.shared.sendDriverStatusNotification(
            reference: testReference,
            status: selectedStatus,
            estimatedMinutes: minutes
        )
        
        alertMessage = "Status notification sent: \(selectedStatus.displayName)"
        showAlert = true
    }
    
    private func generateNewReference() {
        testReference = "VRM-TEST-\(Int.random(in: 1000...9999))"
        alertMessage = "New reference generated: \(testReference)"
        showAlert = true
    }
}

#Preview {
    NotificationTestView()
}
