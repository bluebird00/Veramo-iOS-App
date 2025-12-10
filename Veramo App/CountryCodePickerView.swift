//
//  CountryCodePickerView.swift
//  Veramo App
//
//  Created by rentamac on 12/9/25.
//

import SwiftUI

struct CountryCodePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCountry: CountryCode
    @State private var searchText = ""
    
    private var filteredCountries: [CountryCode] {
        CountryCodeData.shared.search(searchText)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredCountries) { country in
                    Button(action: {
                        selectedCountry = country
                        dismiss()
                    }) {
                        HStack {
                            Text(country.flag)
                                .font(.title2)
                            
                            Text(country.country)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(country.dialCode)
                                .foregroundColor(.secondary)
                            
                            if country.id == selectedCountry.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search country")
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CountryCodePickerView(
        selectedCountry: .constant(CountryCodeData.shared.getDefaultCountryCode())
    )
}
