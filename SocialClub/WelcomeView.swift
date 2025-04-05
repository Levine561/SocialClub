import SwiftUI

struct WelcomeView: View {
    @State private var progress: Double = 0.8

    var body: some View {
        NavigationView {
            ZStack {
                // Foreground content.
                VStack(spacing: 24) {
                    // Removed: Spacer().frame(height: 80) // Ensure content is below the dynamic island.
                    
                    ProgressView(value: progress, total: 1.0)
                        .tint(Color(red: 55/255.0, green: 119/255.0, blue: 1.0))
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                    
                    Text("Welcome to SocialClub")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Spacer().frame(height: 8) // Reduced spacing between title and body
                    
                    // REPLACEMENT: Icons with short descriptions.
                    VStack(spacing: 16) {
                        // Post your sights
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .frame(width: 40, alignment: .center)
                                .foregroundColor(Color.gray)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Post your sights")
                                    .font(.headline)
                                Text("Share and save your adventures with your community!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Explore Hotspots
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.title2)
                                .frame(width: 40, alignment: .center)
                                .foregroundColor(Color.gray)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Explore Hotspots")
                                    .font(.headline)
                                Text("Discover local hotspots and find new things to do!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Join Clubs
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "person.3.fill")
                                .font(.title2)
                                .frame(width: 40, alignment: .center)
                                .foregroundColor(Color.gray)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Join Clubs")
                                    .font(.headline)
                                Text("Expand your network and chat with new people!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Spacer() // Added spacer to push the button to the bottom
                    
                    NavigationLink(destination: ExploreView().navigationBarBackButtonHidden(true)) {
                        Text("Get started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 55/255.0, green: 119/255.0, blue: 1.0))
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .onAppear {
                    progress = 1.0
                }
            }
            .ignoresSafeArea(edges: .top)
        }
    }
}

#Preview {
    WelcomeView()
}
