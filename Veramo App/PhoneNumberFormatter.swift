//
//  PhoneNumberFormatter.swift
//  Veramo App
//
//  Created by rentamac on 12/9/25.
//

import Foundation

struct PhoneNumberFormatter {
    
    /// Formats a phone number string for display (adds spaces for readability)
    /// Example: "+41791234567" -> "+41 79 123 45 67"
    static func format(_ phoneNumber: String) -> String {
        let digitsOnly = phoneNumber.filter { $0.isNumber || $0 == "+" }
        
        // Swiss phone number formatting
        if digitsOnly.hasPrefix("+41") && digitsOnly.count == 12 {
            let countryCode = "+41"
            let index = digitsOnly.index(digitsOnly.startIndex, offsetBy: 3)
            let remaining = String(digitsOnly[index...])
            
            if remaining.count >= 9 {
                let p1 = remaining.prefix(2)
                let p2 = remaining.dropFirst(2).prefix(3)
                let p3 = remaining.dropFirst(5).prefix(2)
                let p4 = remaining.dropFirst(7)
                return "\(countryCode) \(p1) \(p2) \(p3) \(p4)"
            }
        }
        
        // US/Canadian phone number formatting
        if (digitsOnly.hasPrefix("+1") && digitsOnly.count == 12) {
            let countryCode = "+1"
            let index = digitsOnly.index(digitsOnly.startIndex, offsetBy: 2)
            let remaining = String(digitsOnly[index...])
            
            if remaining.count >= 10 {
                let area = remaining.prefix(3)
                let p1 = remaining.dropFirst(3).prefix(3)
                let p2 = remaining.dropFirst(6)
                return "\(countryCode) (\(area)) \(p1)-\(p2)"
            }
        }
        
        // Default: just return cleaned up version
        return digitsOnly
    }
    
    /// Cleans a phone number to just digits and + sign
    /// Example: "+41 79 123 45 67" -> "+41791234567"
    static func clean(_ phoneNumber: String) -> String {
        return phoneNumber.filter { $0.isNumber || $0 == "+" }
    }
    
    /// Validates if a phone number looks valid (has country code and enough digits)
    static func isValid(_ phoneNumber: String) -> Bool {
        let cleaned = clean(phoneNumber)
        
        // Must start with + and have between 10-15 digits total
        guard cleaned.hasPrefix("+") else { return false }
        
        let digitsOnly = cleaned.filter { $0.isNumber }
        return digitsOnly.count >= 10 && digitsOnly.count <= 15
    }
}
