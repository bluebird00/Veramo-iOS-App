//
//  VehicleType.swift.swift
//  Veramo App
//
//  Created by rentamac on 12/6/25.
//

import Foundation

struct VehicleType: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let maxPassengers: Int
}
