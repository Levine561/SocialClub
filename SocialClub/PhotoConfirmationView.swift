import SwiftUI
import AVKit
import FirebaseStorage

struct PhotoConfirmationView: View {
    let backgroundF3F2F8 = Color(red: 243/255, green: 242/255, blue: 248/255)

    let image: UIImage
    let mediaURL: URL
    
    @Environment(\.dismiss) var dismiss
    @State private var navigateToCameraView: Bool = false
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
                                    // Placeholder for post action
                                    print("Post tapped")
                                }) {
                                    Text("Post")
                                        .foregroundColor(.white)
                                        .padding(16)
                                        .frame(maxWidth: 150)
                                        .background(
                                            Capsule().fill(Color(red: 55/255, green: 119/255, blue: 255/255))
                                        )
                                }
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
    }
    
    var isImage: Bool {
        let ext = mediaURL.pathExtension.lowercased()
        return ext == "jpg" || ext == "jpeg" || ext == "png"
    }
}

#Preview {
    PhotoConfirmationView(image: UIImage(contentsOfFile: "path/to/image.jpg")!, mediaURL: URL(string: "https://example.com/image.jpg")!)
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
