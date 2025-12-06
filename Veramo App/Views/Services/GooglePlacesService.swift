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
        
        var fullText: String {
            "\(mainText), \(secondaryText)"
        }
    }
    
    struct AutocompleteResponse: Codable {
        let predictions: [Prediction]
        
        struct Prediction: Codable {
            let placeId: String
            let structuredFormatting: StructuredFormatting
            
            enum CodingKeys: String, CodingKey {
                case placeId = "place_id"
                case structuredFormatting = "structured_formatting"
            }
        }
        
        struct StructuredFormatting: Codable {
            let mainText: String
            let secondaryText: String?
            
            enum CodingKeys: String, CodingKey {
                case mainText = "main_text"
                case secondaryText = "secondary_text"
            }
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
            print("Timer fired, searchin fo: '\(query)'")
            self?.performSearch(query: query)
        }
    }
    
    private func performSearch(query: String) {
        
        isLoading = true
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.replacingOccurrences(of: " ", with: "%20") ?? ""
        print("Encoded query: '\(encodedQuery)'") // Debug
        
        let urlString = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(encodedQuery)&components=country:ch&language=en&key=\(apiKey)"
        
        print("URL: \(urlString)") // Debug
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: AutocompleteResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    print("Error fetching suggestions: \(error)")
                }
            }, receiveValue: { [weak self] response in
                self?.suggestions = response.predictions.map { prediction in
                    PlaceSuggestion(
                        placeId: prediction.placeId,
                        mainText: prediction.structuredFormatting.mainText,
                        secondaryText: prediction.structuredFormatting.secondaryText ?? ""
                    )
                }
            })
    }
    
    func clearSuggestions() {
        debounceTimer?.invalidate()
        suggestions = []
        cancellable?.cancel()
    }
}
