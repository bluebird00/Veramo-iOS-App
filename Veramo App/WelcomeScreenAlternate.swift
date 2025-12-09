//
//  WelcomeScreenAlternate.swift
//  Veramo App
//
//  Created by rentamac on 12/8/25.
//
//  Alternative design with a more premium/luxury feel
//

import SwiftUI

struct WelcomeScreenAlternate: View {
    @Binding var hasSeenWelcome: Bool
    @State private var currentPage = 0
    @State private var opacity: Double = 0
    
    let pages: [WelcomeFeature] = [
        WelcomeFeature(
            title: "Welcome to Veramo",
            subtitle: "Premium Chauffeur Service",
            description: "Experience Swiss luxury transportation at its finest. Professional drivers, premium vehicles, impeccable service.",
            icon: "star.fill",
            systemImage: "car.side.fill"
        ),
        WelcomeFeature(
            title: "Effortless Booking",
            subtitle: "Book in Seconds",
            description: "Reserve your ride with just a few taps. Select your vehicle class, pickup time, and destination.",
            icon: "calendar.badge.checkmark",
            systemImage: "iphone.gen3"
        ),
        WelcomeFeature(
            title: "Your Journey History",
            subtitle: "Always Organized",
            description: "Track upcoming trips and review past journeys. All your bookings in one convenient place.",
            icon: "clock.arrow.circlepath",
            systemImage: "list.bullet.clipboard.fill"
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
                    Text("VERAMO")
                        .font(.system(size: 36, weight: .light, design: .serif))
                        .foregroundColor(.white)
                        .tracking(4)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 60, height: 1)
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
                            withAnimation {
                                hasSeenWelcome = true
                            }
                        }
                    }) {
                        HStack(spacing: 12) {
                            Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
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
                        Button("Skip") {
                            withAnimation {
                                hasSeenWelcome = true
                            }
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
    let icon: String
    let systemImage: String
}

// MARK: - Welcome Feature View

struct WelcomeFeatureView: View {
    let feature: WelcomeFeature
    @State private var animate = false
    
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
                
                // Icon
                Image(systemName: feature.systemImage)
                    .font(.system(size: 70, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    animate = true
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
    WelcomeScreenAlternate(hasSeenWelcome: .constant(false))
}
