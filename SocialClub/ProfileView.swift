//
//  ProfileView.swift
//  SocialClub
//
//  Created by Matthew Levine on 4/2/25.
//

import SwiftUI

struct ProfileView: View {
    @State private var showExplore = false

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    showExplore = true
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title)
                }
                Spacer()
            }
            .padding()
            
            Spacer()
            
            NavigationLink(destination: ExploreView(), isActive: $showExplore) {
                EmptyView()
            }
        }
        .navigationTitle("Profile")
    }
}

#Preview {
    ProfileView()
}
