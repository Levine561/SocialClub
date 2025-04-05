//
//  SplashView.swift
//  SocialClub
//
//  Created by Matthew Levine on 4/4/25.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Spacer()
                Image("SplashImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .offset(y: -50)
                Spacer()
                Text("Keep exploring!")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    SplashView()
}
