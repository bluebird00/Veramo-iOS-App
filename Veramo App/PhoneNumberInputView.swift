//
//  PhoneNumberInputView.swift
//  Veramo App
//
//  Created by rentamac on 12/9/25.
//

import SwiftUI

struct PhoneNumberInputView: View {
    @Binding var countryCode: CountryCode
    @Binding var phoneNumber: String
    @State private var showCountryPicker = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Country Code Selector Button
            Button(action: {
                showCountryPicker = true
            }) {
                HStack(spacing: 6) {
                    Text(countryCode.flag)
                        .font(.title3)
                    
                    Text(countryCode.dialCode)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .cornerRadius(10)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.horizontal, 12),
                    alignment: .bottom
                )
            }
            
            // Phone Number Input Field
            HStack(spacing: 8) {
                Image(systemName: "phone.fill")
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                TextField("Phone number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .autocorrectionDisabled()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.8))
                    .padding(.horizontal),
                alignment: .bottom
            )
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryCodePickerView(selectedCountry: $countryCode)
        }
    }
}

#Preview {
    PhoneNumberInputView(
        countryCode: .constant(CountryCodeData.shared.getDefaultCountryCode()),
        phoneNumber: .constant("791234567")
    )
    .padding()
}
