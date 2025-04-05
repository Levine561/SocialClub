import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct UsernameView: View {
    @State private var username: String = ""
    @State private var isUsernameAvailable: Bool? = nil
    @State private var progress: Double = 0.4
    
    // Function to check if the username is available in Firestore
    private func checkUsernameAvailability() {
        guard !username.isEmpty else {
            isUsernameAvailable = nil
            return
        }
        let db = Firestore.firestore()
        db.collection("users")
            .whereField("username", isEqualTo: username)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking username: \(error.localizedDescription)")
                    isUsernameAvailable = false
                    return
                }
                if let snapshot = snapshot, snapshot.documents.isEmpty {
                    isUsernameAvailable = true
                } else {
                    isUsernameAvailable = false
                }
            }
    }
    
    private func saveUsername() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData(["username": username], merge: true) { error in
            if let error = error {
                print("Error saving username: \(error.localizedDescription)")
            } else {
                print("Username saved successfully for uid: \(uid)")
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Progress Bar indicating the current step in the signup process
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(Color(red: 55/255.0, green: 119/255.0, blue: 1.0))
                .frame(maxWidth: .infinity)
            Text("Create a username")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)
            
            // Username TextField with an availability indicator overlay
            TextField("Username", text: $username)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .overlay(
                    HStack {
                        Spacer()
                        if let available = isUsernameAvailable {
                            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(available ? .green : .red)
                                .padding(.trailing, 8)
                        }
                    }
                )
                .frame(maxWidth: .infinity)
                .onChange(of: username) { _ in
                    checkUsernameAvailability()
                }
            
            Spacer()
            
            // Continue Button that navigates to ProfilePictureView
            NavigationLink(destination: ProfilePictureView().navigationBarBackButtonHidden(true)) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background((username.isEmpty || isUsernameAvailable != true) ? Color(red: 236/255, green: 236/255, blue: 236/255) : Color(red: 55/255, green: 119/255, blue: 1.0))
                    .foregroundColor((username.isEmpty || isUsernameAvailable != true) ? Color(red: 142/255, green: 142/255, blue: 147/255) : Color(red: 255/255, green: 255/255, blue: 255/255))
                    .cornerRadius(8)
            }
            .disabled(username.isEmpty || isUsernameAvailable != true)
            .simultaneousGesture(TapGesture().onEnded {
                saveUsername()
            })
        }
        .frame(maxHeight: .infinity)
        .padding(16)
        .onAppear {
            progress = 0.8
        }
    }
}

#Preview {
    UsernameView()
}
