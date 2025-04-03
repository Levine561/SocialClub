//
//  WelcomeView.swift
//  SocialClub
//
//  Created by Matthew Levine on 4/3/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var progress: Double = 0.8

    var body: some View {
        ZStack {
            // Foreground content.
            VStack(spacing: 16) {
                Spacer().frame(height: 80) // Ensure content is below the dynamic island.
                
                ProgressView(value: progress, total: 1.0)
                    .tint(Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0))
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                    .padding(.horizontal)
                
                Text("Welcome to SocialClub")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Connect, share, and thrive in a vibrant community.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer().frame(height: 40)
                
                Button(action: {
                    // Define the action for the Get Started button here.
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top, 60)
        }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    WelcomeView()
}
