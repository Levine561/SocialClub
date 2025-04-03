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
            // Check if a user is already logged in using Firebase Auth
            if Auth.auth().currentUser != nil && UserDefaults.standard.bool(forKey: "loggedInOnThisDevice") {
                ExploreView()
            } else {
                LoginView()
            }
        }
    }
}
