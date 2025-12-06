//
//  FormTextField.swift
//  Veramo App
//
//  Created by rentamac on 12/6/25.
//

import SwiftUI

struct FormTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .autocorrectionDisabled()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}
