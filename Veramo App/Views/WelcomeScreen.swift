//
//  WelcomeScreen.swift
//  Veramo App
//
//  Created by rentamac on 12/8/25.
//

import SwiftUI

struct WelcomeScreen: View {
    @Binding var hasSeenWelcome: Bool
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Premium Chauffeur Service",
            description: "Experience luxury transportation across Switzerland with professional drivers and premium vehicles.",
            icon: "car.fill",
            accentColor: .black
        ),
        OnboardingPage(
            title: "Easy Booking",
            description: "Book your ride in just a few taps. Choose your vehicle, set your pickup time, and we'll handle the rest.",
            icon: "calendar.badge.checkmark",
            accentColor: .black
        ),
        OnboardingPage(
            title: "Track Your Trips",
            description: "View your upcoming rides and trip history. Stay organized with all your bookings in one place.",
            icon: "list.bullet.clipboard",
            accentColor: .black
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        withAnimation {
                            hasSeenWelcome = true
                        }
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page indicator and continue button
                VStack(spacing: 32) {
                    // Custom page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.black : Color.gray.opacity(0.3))
                                .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    
                    // Continue/Get Started button
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            withAnimation {
                                hasSeenWelcome = true
                            }
                        }
                    }) {
                        Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.black, Color(.darkGray)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let title: String
    let description: String
    let icon: String
    let accentColor: Color
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon with animated background
            ZStack {
                Circle()
                    .fill(page.accentColor.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                Circle()
                    .fill(page.accentColor.opacity(0.2))
                    .frame(width: 150, height: 150)
                
                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundColor(page.accentColor)
            }
            
            Spacer()
            
            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    WelcomeScreen(hasSeenWelcome: .constant(false))
}
