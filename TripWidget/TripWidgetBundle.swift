//
//  TripWidgetBundle.swift
//  TripWidget
//
//  Created by Rainer Schanung on 14/12/25.
//

import WidgetKit
import SwiftUI

@main
struct TripWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Live Activity widget for trip tracking
        TripLiveActivity()
    }
}
