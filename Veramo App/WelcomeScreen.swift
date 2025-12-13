//
//  WelcomeScreenAlternate.swift
//  Veramo App
//
//  Created by rentamac on 12/8/25.
//
//  Alternative design with a more premium/luxury feel
//

import SwiftUI

struct WelcomeScreen: View {
    @Binding var hasSeenWelcome: Bool
    @State private var currentPage = 0
    @State private var opacity: Double = 0
    
    let pages: [WelcomeFeature] = [
        WelcomeFeature(
            // TRANSLATE: Main welcome screen title - introduces the Veramo brand
            title: String(localized: "welcome.page1.title"),
            // TRANSLATE: Subtitle describing the service type (chauffeur/luxury transportation)
            subtitle: String(localized: "welcome.page1.subtitle"),
            // TRANSLATE: Description of the premium service features
            description: String(localized: "welcome.page1.description")
        ),
        WelcomeFeature(
            // TRANSLATE: Title for the booking feature page
            title: String(localized: "welcome.page2.title"),
            // TRANSLATE: Subtitle emphasizing booking speed/ease
            subtitle: String(localized: "welcome.page2.subtitle"),
            // TRANSLATE: Description of how the booking process works
            description: String(localized: "welcome.page2.description")
        ),
        WelcomeFeature(
            // TRANSLATE: Title for the trip history feature page
            title: String(localized: "welcome.page3.title"),
            // TRANSLATE: Subtitle emphasizing organization/convenience
            subtitle: String(localized: "welcome.page3.subtitle"),
            // TRANSLATE: Description of trip tracking features
            description: String(localized: "welcome.page3.description")
        )
    ]
    
    var body: some View {
        ZStack {
            // Elegant background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Logo/Brand area
                VStack(spacing: 8) {
                    // TRANSLATE: Brand name - consider keeping as "Veramo" in all languages if it's a brand name
                    Text("welcome.brand.name", comment: "App brand name displayed on welcome screen")
                        .font(.custom("SF Pro", size: 36))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .tracking(4)
                    

                }
                .padding(.top, 60)
                .opacity(opacity)
                
                Spacer()
                
                // Feature pages
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        WelcomeFeatureView(feature: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 500)
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: 24) {
                    // Page dots
                    HStack(spacing: 12) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                                .frame(width: currentPage == index ? 32 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    
                    // Action button
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } else {
                            // No animation wrapper - prevents animation bleed to HomeView
                            hasSeenWelcome = true
                        }
                    }) {
                        HStack(spacing: 12) {
                            // TRANSLATE: Button text - "Get Started" for last page, "Continue" for others
                            Text(currentPage == pages.count - 1 ? 
                                 // TRANSLATE: Final call-to-action button on last welcome page
                                 String(localized: "welcome.button.getStarted", comment: "Button to finish onboarding and start using the app") : 
                                 // TRANSLATE: Button to advance to next welcome page
                                 String(localized: "welcome.button.continue", comment: "Button to go to next onboarding page"))
                                .font(.system(size: 18, weight: .medium))
                            
                            Image(systemName: currentPage == pages.count - 1 ? "arrow.right.circle.fill" : "arrow.right")
                                .font(.system(size: 20))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white)
                        )
                    }
                    .padding(.horizontal, 32)
                    
                    // Skip button
                    if currentPage < pages.count - 1 {
                        Button {
                            // No animation wrapper - prevents animation bleed to HomeView
                            hasSeenWelcome = true
                        } label: {
                            // TRANSLATE: Button to skip the welcome/onboarding screens
                            Text("welcome.button.skip", comment: "Button to skip onboarding and go directly to the app")
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                opacity = 1
            }
        }
    }
}

// MARK: - Welcome Feature Model

struct WelcomeFeature {
    let title: String
    let subtitle: String
    let description: String
    
    
}

// MARK: - Welcome Feature View

struct WelcomeFeatureView: View {
    let feature: WelcomeFeature
    @State private var animate = false
    @State private var pulsate = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(animate ? 1.1 : 1.0)
                
                // Inner circle
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 140, height: 140)
                
                // Small pulsating center circle
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .scaleEffect(pulsate ? 1.3 : 1.0)
                    .opacity(pulsate ? 0.6 : 1.0)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    animate = true
                }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulsate = true
                }
            }
            
            // Content
            VStack(spacing: 12) {
                // Subtitle
                Text(feature.subtitle.uppercased())
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(2)
                
                // Title
                Text(feature.title)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Description
                Text(feature.description)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    WelcomeScreen(hasSeenWelcome: .constant(false))
}
