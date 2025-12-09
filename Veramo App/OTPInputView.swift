//
//  OTPInputView.swift
//  Veramo App
//
//  Created by rentamac on 12/9/25.
//

import SwiftUI

struct OTPInputView: View {
    @Binding var code: String
    @FocusState private var focusedField: Int?
    let onComplete: () -> Void
    let isLoading: Bool
    
    private let digitCount = 6
    
    var body: some View {
        VStack(spacing: 20) {
            // OTP Input Fields
            HStack(spacing: 12) {
                ForEach(0..<digitCount, id: \.self) { index in
                    OTPDigitField(
                        digit: digitAt(index),
                        isFocused: focusedField == index
                    )
                    .focused($focusedField, equals: index)
                    .onChange(of: code) { oldValue, newValue in
                        handleCodeChange(oldValue: oldValue, newValue: newValue)
                    }
                }
            }
            .overlay {
                // Hidden TextField that actually captures the input
                TextField("", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($focusedField, equals: 0)
                    .opacity(0)
                    .frame(width: 1, height: 1)
                    .onChange(of: code) { oldValue, newValue in
                        // Limit to 6 digits
                        let filtered = String(newValue.prefix(digitCount).filter { $0.isNumber })
                        if filtered != newValue {
                            code = filtered
                        }
                        
                        // Auto-verify when complete
                        if filtered.count == digitCount && !isLoading {
                            print("✅ [OTP] All 6 digits entered, auto-verifying...")
                            // Small delay for better UX
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                onComplete()
                            }
                        }
                    }
            }
            .disabled(isLoading)
            
            // Loading Spinner Below
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.9)
                    Text("Verifying...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .onAppear {
            // Auto-focus first field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = 0
            }
        }
    }
    
    private func digitAt(_ index: Int) -> String {
        guard index < code.count else { return "" }
        let digitIndex = code.index(code.startIndex, offsetBy: index)
        return String(code[digitIndex])
    }
    
    private func handleCodeChange(oldValue: String, newValue: String) {
        // Update focus based on code length
        if newValue.count > oldValue.count && newValue.count < digitCount {
            focusedField = newValue.count
        } else if newValue.count < oldValue.count {
            focusedField = max(0, newValue.count)
        }
    }
}

struct OTPDigitField: View {
    let digit: String
    let isFocused: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(digit)
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.primary)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
            
            // Underline
            Rectangle()
                .fill(isFocused ? Color.black : Color.gray.opacity(0.3))
                .frame(height: 2)
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: digit)
    }
}

#Preview {
    VStack(spacing: 40) {
        // Empty state
        OTPInputView(code: .constant(""), onComplete: {}, isLoading: false)
        
        // Partial fill
        OTPInputView(code: .constant("123"), onComplete: {}, isLoading: false)
        
        // Loading state
        OTPInputView(code: .constant("123456"), onComplete: {}, isLoading: true)
    }
    .padding()
}
