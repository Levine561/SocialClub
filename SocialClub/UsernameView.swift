import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct UsernameView: View {
    @State private var username: String = ""
    @State private var errorMessage: String?
    @State private var isUsernameAvailable: Bool?
    @State private var isChecking: Bool = false
    @State private var shouldNavigate = false
    @State private var progress: Double = 0.4
    
    // Reference to your Firestore database
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ProgressView(value: progress, total: 1.0)
                    .tint(Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0))
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                
                Text("Create a Username")
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
                
                NavigationLink(destination: ProfilePictureView().navigationBarBackButtonHidden(true), isActive: $shouldNavigate) {
                    EmptyView()
                }
                .hidden()
                
                Spacer()
            }
            .padding()
            .onAppear {
                withAnimation(.linear(duration: 1.0)) {
                    progress = 0.6
                }
            }
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
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard isUsernameAvailable == true, let user = Auth.auth().currentUser else {
            return
        }
        
        // Update the user's document with the chosen username
        db.collection("users").document(user.uid).setData(["username": trimmedUsername], merge: true) { error in
            if let error = error {
                errorMessage = "Error updating username: \(error.localizedDescription)"
            } else {
                shouldNavigate = true
            }
        }
    }
}

struct UsernameView_Previews: PreviewProvider {
    static var previews: some View {
        UsernameView()
    }
}
