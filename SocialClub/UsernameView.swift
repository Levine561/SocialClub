import SwiftUI
import FirebaseFirestore

struct UsernameView: View {
    @State private var username: String = ""
    @State private var errorMessage: String?
    @State private var isUsernameAvailable: Bool?
    @State private var isChecking: Bool = false
    @State private var shouldNavigate = false
    
    // Reference to your Firestore database
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Create a username")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                TextField("Enter username", text: $username)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .autocapitalization(.none)
                    .onChange(of: username) { _ in
                        isUsernameAvailable = nil
                        checkUsernameAvailability()
                    }
                
                if !username.trimmingCharacters(in: .whitespaces).isEmpty {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    } else if let available = isUsernameAvailable {
                        Text(available ? "Username is available" : "Username is taken")
                            .foregroundColor(available ? .green : .red)
                            .font(.footnote)
                    }
                }
                
                Button(action: {
                    continueAction()
                }) {
                    if isChecking {
                        ProgressView()
                    } else {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0))
                            .cornerRadius(8)
                            .opacity(username.trimmingCharacters(in: .whitespaces).isEmpty || isChecking || isUsernameAvailable != true ? 0.5 : 1.0)
                    }
                }
                .disabled(username.trimmingCharacters(in: .whitespaces).isEmpty || isChecking || isUsernameAvailable != true)
                
                NavigationLink(destination: ProfilePictureView(), isActive: $shouldNavigate) {
                    EmptyView()
                }
                .hidden()
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // Function to check username availability using Firestore
    private func checkUsernameAvailability() {
        // Clear previous state
        isUsernameAvailable = nil
        errorMessage = nil
        isChecking = true
        
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard !trimmedUsername.isEmpty else {
            errorMessage = nil
            isUsernameAvailable = nil
            isChecking = false
            return
        }
        
        // Assume you have a "users" collection where each document has a "username" field.
        db.collection("users")
            .whereField("username", isEqualTo: trimmedUsername)
            .getDocuments { snapshot, error in
                isChecking = false
                if let error = error {
                    errorMessage = "Error checking username: \(error.localizedDescription)"
                    return
                }
                
                // If no documents match, then the username is available.
                if let snapshot = snapshot, snapshot.documents.isEmpty {
                    isUsernameAvailable = true
                } else {
                    isUsernameAvailable = false
                }
            }
    }
    
    private func continueAction() {
        shouldNavigate = true
    }
}

struct UsernameView_Previews: PreviewProvider {
    static var previews: some View {
        UsernameView()
    }
}
