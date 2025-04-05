import SwiftUI
import AVKit
import FirebaseStorage

struct PhotoConfirmationView: View {
    let backgroundF3F2F8 = Color(red: 243/255, green: 242/255, blue: 248/255)

    let image: UIImage
    let mediaURL: URL
    
    @Environment(\.dismiss) var dismiss
    @State private var navigateToCameraView: Bool = false
    @State private var isImageLoaded = false
    @State private var caption: String = ""
    @State private var showEnlargedImage = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Sights")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                HStack {
                    // Left: Back button with chevron
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
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22))
                            .foregroundColor(.black)
                    }
                    Spacer()
                    Button(action: {
                        // Action for Post button
                        print("Post tapped: \(caption)")
                    }) {
                        Text("Post")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 55/255, green: 119/255, blue: 255/255))
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 16)
            
            Divider()
                .background(Color.gray)
                .padding(.top, 8)

            // Main image or video
            if isImage {
                ZStack {
                    if !isImageLoaded {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .redacted(reason: .placeholder)
                    }
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .onAppear {
                            isImageLoaded = true
                        }
                        .onTapGesture {
                            showEnlargedImage = true
                        }
                }
                .frame(width: UIScreen.main.bounds.width - 32, height: 350)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            } else {
                HStack {
                    VideoPlayer(player: AVPlayer(url: mediaURL))
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.trailing, 16) // ensure some trailing spacing for video
            }

            // Caption input field
            TextField("Enter caption", text: $caption)
                .padding()
                .cornerRadius(8)
                .padding(.horizontal, 16)

            // Character count
            Text("\(caption.count)/50")
                .foregroundColor(.gray)
                .font(.caption)
                .padding(.horizontal, 16)
                .padding(.top, 4)

            Spacer()
        }
        .fullScreenCover(isPresented: $navigateToCameraView) {
            CameraView()
        }
        .fullScreenCover(isPresented: $showEnlargedImage) {
            ZStack(alignment: .topTrailing) {
                Color.black.edgesIgnoringSafeArea(.all)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                Button(action: {
                    showEnlargedImage = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                .padding()
            }
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
