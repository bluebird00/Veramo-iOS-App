//
//  PlaceLocalizationHelper.swift
//  Veramo App
//
//  Created for multilingual place name handling
//

import Foundation

/// Helper for managing place names in multiple languages
/// 
/// This utility ensures place names are displayed in the user's language
/// while always storing them in English in the database.
struct PlaceLocalizationHelper {
    
    /// Represents a place with both localized and English names
    struct LocalizedPlace {
        let displayName: String      // Name to show to user (in their language)
        let databaseName: String      // Name to store in database (always English)
        let placeId: String?          // Google Place ID for consistency
        
        init(displayName: String, databaseName: String, placeId: String? = nil) {
            self.displayName = displayName
            self.databaseName = databaseName
            self.placeId = placeId
        }
    }
    
    /// Gets the current user's language code
    static var currentLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }
    
    /// Checks if the user's language is English
    static var isUserLanguageEnglish: Bool {
        currentLanguageCode == "en"
    }
    
    /// When receiving place names from backend (always in English),
    /// you can use Google Place Details API to fetch the localized version
    /// if the user is not using English.
    ///
    /// Example usage:
    /// ```swift
    /// if let placeId = trip.pickupPlaceId, !PlaceLocalizationHelper.isUserLanguageEnglish {
    ///     // Fetch localized name using Google Place Details API
    ///     let localizedName = await PlaceDetailsService.getPlaceName(
    ///         placeId: placeId,
    ///         language: PlaceLocalizationHelper.currentLanguageCode
    ///     )
    ///     // Use localizedName for display
    /// } else {
    ///     // Use English name from database
    /// }
    /// ```
}

// MARK: - Extension for GooglePlacesService.PlaceSuggestion

extension GooglePlacesService.PlaceSuggestion {
    /// Creates a LocalizedPlace from this suggestion
    var asLocalizedPlace: PlaceLocalizationHelper.LocalizedPlace {
        PlaceLocalizationHelper.LocalizedPlace(
            displayName: fullText,
            databaseName: fullTextEnglish,
            placeId: placeId
        )
    }
}
