import SwiftUI
import FirebaseStorage

struct ProfilePictureView: View {
    var username: String = ""
    @State private var selectedImage: UIImage?
    @State private var errorMessage: String?
    @State private var isUploading: Bool = false
    @State private var isShowingImagePicker: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Add a Profile Picture")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Username: \(username)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Display selected image or a placeholder circle.
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                } else {
                    Circle()
                        .fill(Color(UIColor.secondarySystemBackground))
                        .frame(width: 150, height: 150)
                        .overlay(
                            Image(systemName: "person.crop.circle.fill.badge.plus")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        )
                }
                
                // Button to show the image picker.
                Button(action: {
                    isShowingImagePicker = true
                }) {
                    Text("Choose Photo")
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0), lineWidth: 2)
                        )
                }
                
                // Display error messages if any.
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                
                // Continue button to upload the selected image.
                Button(action: {
                    uploadProfilePicture()
                }) {
                    if isUploading {
                        ProgressView()
                    } else {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0))
                            .cornerRadius(8)
                            .opacity(selectedImage == nil || isUploading ? 0.5 : 1.0)
                    }
                }
                .disabled(selectedImage == nil || isUploading)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(image: $selectedImage)
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
                    // Proceed to update the user's profile in Firestore or navigate to the next screen.
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
