import SwiftUI
import AVKit
import FirebaseStorage
import FirebaseFirestore
import CoreLocation

struct PhotoConfirmationView: View {
    let backgroundF3F2F8 = Color(red: 243/255, green: 242/255, blue: 248/255)

    let image: UIImage
    let mediaURL: URL
    let photoLocation: CLLocationCoordinate2D?
    
    @Environment(\.dismiss) var dismiss
    @State private var navigateToCameraView: Bool = false
    @State private var navigateToExploreView: Bool = false
    @State private var shareComment: String = ""
    @State private var isImageLoaded = false
    @State private var overlayText: String = ""
    @State private var textOffset: CGSize = .zero
    @State private var isEditingText: Bool = false
    @State private var textScale: CGFloat = 1.0
    @State private var textRotation: Angle = .zero
    @FocusState private var textFieldIsFocused: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Main image or video
                if isImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .ignoresSafeArea()
                        .onAppear {
                            isImageLoaded = true
                        }
                        .onTapGesture {
                            if textFieldIsFocused {
                                textFieldIsFocused = false
                                if overlayText.isEmpty {
                                    isEditingText = false
                                }
                            } else {
                                isEditingText = true
                                textFieldIsFocused = true
                            }
                        }
                        .overlay(
                            Button(action: {
                                // Delete from Firebase Storage
                                let storageRef = Storage.storage().reference(forURL: mediaURL.absoluteString)
                                storageRef.delete { error in
                                    if let error = error {
                                        print("Failed to delete photo from Storage: \(error)")
                                    } else {
                                        print("Photo successfully deleted from Firebase Storage.")
                                    }
                                    
                                    // Delete Firestore document that contains location and other metadata
                                    let db = Firestore.firestore()
                                    let docID = mediaURL.lastPathComponent
                                    db.collection("photos").document(docID).delete { error in
                                        if let error = error {
                                            print("Failed to delete Firestore document: \(error)")
                                        } else {
                                            print("Firestore document successfully deleted.")
                                        }
                                        // Navigate back
                                        navigateToCameraView = true
                                    }
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(
                                        Circle().fill(Color.black.opacity(0.5))
                                    )
                            }
                            .padding(.top, 54)
                            .padding(.leading, 16)
                            , alignment: .topLeading
                        )
                        .overlay(
                            Group {
                                if isEditingText || !overlayText.isEmpty {
                                    TextField("", text: $overlayText)
                                        .focused($textFieldIsFocused)
                                        .padding(8)
                                        .background(Color(white: 0.1, opacity: 0.5))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                        .offset(textOffset)
                                        .scaleEffect(textScale)
                                        .rotationEffect(textRotation)
                                        .gesture(
                                            DragGesture()
                                                .onChanged { value in
                                                    textOffset = CGSize(width: 0, height: value.translation.height)
                                                }
                                        )
                                        .onSubmit {
                                            textFieldIsFocused = false
                                            if overlayText.isEmpty {
                                                isEditingText = false
                                            }
                                        }
                                        .simultaneousGesture(
                                            MagnificationGesture()
                                                .onChanged { scale in
                                                    textScale = scale
                                                }
                                        )
                                        .simultaneousGesture(
                                            RotationGesture()
                                                .onChanged { angle in
                                                    textRotation = angle
                                                }
                                        )
                                }
                            },
                            alignment: .center
                        )
                        .overlay(
                            VStack {
                                Spacer()
                                Button(action: {
                                    // Create a composite image with the overlay text (if overlayText is empty, this returns the original image)
                                    let compositeImage = compositeImageWithText(image: image, text: overlayText)
                                    guard let imageData = compositeImage.jpegData(compressionQuality: 0.8) else {
                                        print("Failed to convert composite image to JPEG data.")
                                        return
                                    }
                                    let storageRef = Storage.storage().reference(forURL: mediaURL.absoluteString)

                                    // Create metadata and attach location if available
                                    let newMetadata = StorageMetadata()
                                    if let location = photoLocation {
                                        newMetadata.customMetadata = ["location": "\(location.latitude),\(location.longitude)"]
                                    }

                                    storageRef.putData(imageData, metadata: newMetadata) { metadata, error in
                                        if let error = error {
                                            print("Failed to update image with text: \(error)")
                                        } else {
                                            print("Image updated with text successfully.")

                                            // Write metadata to Firestore
                                            let db = Firestore.firestore()
                                            let docID = mediaURL.lastPathComponent
                                            var data: [String: Any] = [
                                                "mediaURL": mediaURL.absoluteString,
                                                "timestamp": FieldValue.serverTimestamp()
                                            ]
                                            if let location = photoLocation {
                                                data["location"] = "\(location.latitude),\(location.longitude)"
                                            }
                                            if !overlayText.isEmpty {
                                                data["overlayText"] = overlayText
                                            }

                                            db.collection("photos").document(docID).setData(data) { error in
                                                if let error = error {
                                                    print("Error writing Firestore document: \(error)")
                                                } else {
                                                    print("Firestore document successfully written.")
                                                }
                                                DispatchQueue.main.async {
                                                    navigateToExploreView = true
                                                }
                                            }
                                        }
                                    }
                                }, label: {
                                    Text("Post")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(16)
                                        .frame(maxWidth: 150)
                                        .background(
                                            Capsule().fill(Color(red: 55/255, green: 119/255, blue: 255/255))
                                        )
                                })
                                .padding(.bottom, 56)
                            }, alignment: .bottom
                        )
                } else {
                    ZStack {
                        VideoPlayer(player: AVPlayer(url: mediaURL))
                        
                        Button(action: {
                            // Delete from Firebase
                            let ref = Storage.storage().reference(forURL: mediaURL.absoluteString)
                            ref.delete { error in
                                if let error = error {
                                    print("Failed to delete photo: \(error)")
                                } else {
                                    print("Photo successfully deleted from Firebase.")
                                }
                                // Navigate back
                                navigateToCameraView = true
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(
                                    Circle().fill(Color.black.opacity(0.5))
                                )
                        }
                        .padding(.top, 16)
                        .padding(.leading, 16)
                    }
                    .padding(.top, 16)
                    .padding(.trailing, 16) // ensure some trailing spacing for video
                    .edgesIgnoringSafeArea(.top)
                }

                Spacer()

            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(Color.black)
        .fullScreenCover(isPresented: $navigateToCameraView) {
            CameraView()
        }
        .fullScreenCover(isPresented: $navigateToExploreView) {
            ExploreView()
        }
    }
    
    var isImage: Bool {
        let ext = mediaURL.pathExtension.lowercased()
        return ext == "jpg" || ext == "jpeg" || ext == "png"
    }
}

#Preview {
    PhotoConfirmationView(image: UIImage(contentsOfFile: "path/to/image.jpg")!, mediaURL: URL(string: "https://example.com/image.jpg")!, photoLocation: nil)
}

private func compositeImageWithText(image: UIImage, text: String) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: image.size)
    let compositeImage = renderer.image { context in
        // Draw the original image
        image.draw(in: CGRect(origin: .zero, size: image.size))
        
        // Only add text container if there is text
        guard !text.isEmpty else { return }
        
        // Define text attributes
        let font = UIFont.boldSystemFont(ofSize: 40)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white
        ]
        
        // Calculate the size of the text
        let textSize = (text as NSString).size(withAttributes: textAttributes)
        
        // Define padding for vertical space in the container
        let verticalPadding: CGFloat = 16
        // Container spans the full width of the image and its height is text height plus vertical padding
        let containerHeight = textSize.height + verticalPadding
        let containerRect = CGRect(x: 0,
                                   y: (image.size.height - containerHeight) / 2,
                                   width: image.size.width,
                                   height: containerHeight)
        
        // Draw the text container with a semi-transparent dark background (alpha 0.5) and no corner radius
        UIColor(white: 0.1, alpha: 0.5).setFill()
        UIRectFill(containerRect)
        
        // Position the text inside the container (centered)
        let textRect = CGRect(x: (containerRect.width - textSize.width) / 2,
                              y: containerRect.origin.y + (containerRect.height - textSize.height) / 2,
                              width: textSize.width,
                              height: textSize.height)
        
        // Draw the text onto the image
        (text as NSString).draw(in: textRect, withAttributes: textAttributes)
    }
    return compositeImage
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
