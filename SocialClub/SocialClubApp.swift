import SwiftUI
import Firebase
import FirebaseAuth

@main
struct SocialClubApp: App {
    // Initialize Firebase when the app starts.
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var isActive = false
    
    var body: some View {
        Group {
            if isActive {
                // After splash screen, check authentication status
                if Auth.auth().currentUser != nil {
                    ExploreView()
                } else {
                    LoginView()
                }
            } else {
                SplashView()
            }
        }
        .onAppear {
            // Duration of the splash screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isActive = true
                }
            }
        }
    }
}
