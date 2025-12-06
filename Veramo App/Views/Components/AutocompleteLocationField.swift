import SwiftUI

struct AutocompleteLocationField: View {
    let icon: String
    let iconColor: Color
    let placeholder: String
    @Binding var text: String
    @ObservedObject var placesService: GooglePlacesService
    let isFocused: Bool
    let onFocus: () -> Void
    let onSelect: (GooglePlacesService.PlaceSuggestion) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(iconColor)
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .font(.body)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .textContentType(.none) .onTapGesture { onFocus() }
                    .onChange(of: text) { _, newValue in
                        print("Text changed to: '\(newValue)'") // Debug
                        placesService.fetchSuggestions(for: newValue)
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        placesService.clearSuggestions()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 8)
            
            // Suggestions dropdown
            if isFocused && !placesService.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(placesService.suggestions) { suggestion in
                        Button(action: { onSelect(suggestion) }) {
                            HStack(spacing: 20) {
                                
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(suggestion.mainText)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text(suggestion.secondaryText)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 15)
                            .padding(.horizontal, 20)
                        }
                        
                        if suggestion != placesService.suggestions.last {
                            Divider()
                                .padding(.leading, 32)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            }
        }
    }
}
