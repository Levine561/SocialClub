import SwiftUI
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestore

struct ProfilePictureView: View {
    @State private var selectedImage: UIImage?
    @State private var errorMessage: String?
    @State private var isUploading: Bool = false
    @State private var isShowingImagePicker: Bool = false
    @State private var progress: Double = 0.6
    @State private var navigateToWelcome: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                ProgressView(value: progress, total: 1.0)
                    .tint(Color(red: 135/255.0, green: 173/255.0, blue: 255/255.0))
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)

                Text("Add a profile picture")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    // Display selected image or a placeholder circle, both tappable to open the camera roll.
                    Button(action: {
                        isShowingImagePicker = true
                    }) {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 200, height: 200)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(UIColor.secondarySystemBackground))
                                .frame(width: 200, height: 200)
                                .overlay(
                                    Image(systemName: "person.crop.circle.fill.badge.plus")
                                        .font(.system(size: 70))
                                        .foregroundColor(.gray)
                                )
                        }
                    }

                    // Tertiary button for choosing photo.
                    Button(action: {
                        isShowingImagePicker = true
                    }) {
                        Text("Select photo")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 255/255.0, green: 49/255.0, blue: 95/255.0))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                    }
                }
                
                // Display error messages if any.
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                
                Spacer()
                
                // Continue button to upload the selected image.
                Button(action: {
                    uploadProfilePicture()
                }) {
                    if isUploading {
                        ProgressView()
                    } else {
                        let isDisabled = selectedImage == nil || isUploading
                        Text("Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(isDisabled ? Color(red: 142/255.0, green: 142/255.0, blue: 147/255.0) : Color(red: 255/255.0, green: 255/255.0, blue: 255/255.0))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isDisabled ? Color(red: 236/255.0, green: 236/255.0, blue: 236/255.0) : Color(red: 255/255.0, green: 49/255.0, blue: 95/255.0))
                            .cornerRadius(8)
                    }
                }
                .disabled(selectedImage == nil || isUploading)
                
                NavigationLink(
                    destination: WelcomeView().navigationBarBackButtonHidden(true),
                    isActive: $navigateToWelcome,
                    label: { EmptyView() }
                ).hidden()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .onAppear {
                progress = 0.8
            }
        }
    }
    
    // Function to upload the selected image to Firebase Storage.
    private func uploadProfilePicture() {
        guard let image = selectedImage, let data = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "No image selected."
            return
        }
        
        isUploading = true
        
        // Create a reference in Firebase Storage
        let storageRef = Storage.storage().reference().child("profile_pictures/\(UUID().uuidString).jpg")
        storageRef.putData(data, metadata: nil) { metadata, error in
            isUploading = false
            if let error = error {
                errorMessage = "Upload error: \(error.localizedDescription)"
                return
            }
            // Optionally, retrieve the download URL of the uploaded image.
            storageRef.downloadURL { url, error in
                if let error = error {
                    errorMessage = "Download URL error: \(error.localizedDescription)"
                    return
                }
                if let url = url {
                    print("Profile picture URL: \(url.absoluteString)")
                    // Update the user's profile in Firestore with the new profile picture URL.
                    if let currentUser = Auth.auth().currentUser {
                        let db = Firestore.firestore()
                        db.collection("users").document(currentUser.uid).updateData([
                            "profilePictureURL": url.absoluteString
                        ]) { error in
                            if let error = error {
                                errorMessage = "Firestore update error: \(error.localizedDescription)"
                            } else {
                                print("User profile picture updated successfully.")
                                navigateToWelcome = true
                                // Optionally, navigate to the next screen or perform other actions.
                            }
                        }
                    } else {
                        errorMessage = "No authenticated user found."
                    }
                }
            }
        }
    }
}

struct ProfilePictureView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilePictureView()
    }
}

// MARK: - ImagePicker Implementation
// This struct wraps UIImagePickerController for use in SwiftUI.
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// New view to recall and display the user's profile picture from Firestore
struct RecalledProfilePictureView: View {
    @State private var profilePictureURL: String?
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading...")
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else if let urlString = profilePictureURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        Text("Failed to load image")
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: 200, height: 200)
                .clipShape(Circle())
            } else {
                Text("No profile picture available")
            }
        }
        .onAppear {
            loadProfilePictureURL()
        }
    }
    
    private func loadProfilePictureURL() {
        guard let currentUser = Auth.auth().currentUser else {
            self.errorMessage = "No authenticated user found."
            self.isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(currentUser.uid).getDocument { snapshot, error in
            if let error = error {
                self.errorMessage = "Error fetching user data: \(error.localizedDescription)"
            } else if let data = snapshot?.data(), let url = data["profilePictureURL"] as? String {
                self.profilePictureURL = url
            } else {
                self.errorMessage = "Profile picture URL not found."
            }
            self.isLoading = false
        }
    }
}
