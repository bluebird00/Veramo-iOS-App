//
//  GooglePlacesService.swift
//  Veramo App
//
//  Created by rentamac on 12/6/25.
import Foundation
import Combine

class GooglePlacesService: ObservableObject {
    
    private let apiKey: String
    
    private var debounceTimer: Timer?
    
    @Published var suggestions: [PlaceSuggestion] = []
    @Published var isLoading = false
    
    private var cancellable: AnyCancellable?
    
    init() {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["GOOGLE_PLACES_API_KEY"] as? String else {
            fatalError("Missing Secrets.plist or GOOGLE_PLACES_API_KEY")
        }
        self.apiKey = key
    }
    
    struct PlaceSuggestion: Identifiable, Hashable {
        let id = UUID()
        let placeId: String
        let mainText: String
        let secondaryText: String
        let mainTextEnglish: String  // English version for database
        let secondaryTextEnglish: String  // English version for database
        
        var fullText: String {
            "\(mainText), \(secondaryText)"
        }
        
        var fullTextEnglish: String {
            "\(mainTextEnglish), \(secondaryTextEnglish)"
        }
    }
    
    // New Places API response structure
    struct AutocompleteResponse: Codable {
        let suggestions: [Suggestion]
        
        struct Suggestion: Codable {
            let placePrediction: PlacePrediction
        }
        
        struct PlacePrediction: Codable {
            let placeId: String
            let text: TextContent
            let structuredFormat: StructuredFormat
        }
        
        struct TextContent: Codable {
            let text: String
        }
        
        struct StructuredFormat: Codable {
            let mainText: TextContent
            let secondaryText: TextContent?
        }
    }
    
    func fetchSuggestions(for query: String) {
        // Cancel any pending request
        debounceTimer?.invalidate()
        
        guard !query.isEmpty else {
            suggestions = []
            return
        }
        
        // Debounce: wait 300ms before making the API call
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.performSearch(query: query)
        }
    }
    
    private func performSearch(query: String) {
        isLoading = true
        
        // Get user's preferred language
        let userLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        
        // New Places API uses POST requests
        guard let url = URL(string: "https://places.googleapis.com/v1/places:autocomplete") else {
            isLoading = false
            return
        }
        
        // Create request bodies for both localized and English versions
        let localizedBody: [String: Any] = [
            "input": query,
            "languageCode": userLanguage,
            "regionCode": "ch",  // ccTLD format for Switzerland
            "includedRegionCodes": ["CH"]  // ISO 3166-1 format
        ]
        
        let englishBody: [String: Any] = [
            "input": query,
            "languageCode": "en",
            "regionCode": "ch",  // ccTLD format for Switzerland
            "includedRegionCodes": ["CH"]  // ISO 3166-1 format
        ]
        
        // Create the publishers for both requests
        let localizedPublisher = createAutocompletePublisher(url: url, body: localizedBody)
        let englishPublisher = createAutocompletePublisher(url: url, body: englishBody)
        
        // Combine both requests
        cancellable = Publishers.Zip(localizedPublisher, englishPublisher)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
            }, receiveValue: { [weak self] localizedResponse, englishResponse in
                // Create a dictionary to map place IDs to English versions
                let englishMap = Dictionary(uniqueKeysWithValues: englishResponse.suggestions.map {
                    ($0.placePrediction.placeId, $0.placePrediction.structuredFormat)
                })
                
                self?.suggestions = localizedResponse.suggestions.compactMap { suggestion in
                    let prediction = suggestion.placePrediction
                    guard let englishVersion = englishMap[prediction.placeId] else {
                        return nil
                    }
                    
                    return PlaceSuggestion(
                        placeId: prediction.placeId,
                        mainText: prediction.structuredFormat.mainText.text,
                        secondaryText: prediction.structuredFormat.secondaryText?.text ?? "",
                        mainTextEnglish: englishVersion.mainText.text,
                        secondaryTextEnglish: englishVersion.secondaryText?.text ?? ""
                    )
                }
            })
    }
    
    private func createAutocompletePublisher(url: URL, body: [String: Any]) -> AnyPublisher<AutocompleteResponse, Error> {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        request.httpBody = httpBody
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: AutocompleteResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func clearSuggestions() {
        debounceTimer?.invalidate()
        suggestions = []
        cancellable?.cancel()
    }
}
