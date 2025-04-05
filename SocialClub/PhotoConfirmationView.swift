//
//  PhotoConfirmationView.swift
//  SocialClub
//
//  Created by Matthew Levine on 4/1/25.
//

import SwiftUI
import AVKit
import FirebaseStorage

struct PhotoConfirmationView: View {
    let image: UIImage
    let mediaURL: URL
    
    @Environment(\.dismiss) var dismiss
    @State private var navigateToCameraView: Bool = false
    
    var body: some View {
        ZStack {
            // Full-screen media
            if isImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea()
            } else {
                VideoPlayer(player: AVPlayer(url: mediaURL))
                    .ignoresSafeArea()
            }

            // X button in top-left corner
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button(action: {
                        // Delete from Firebase
                        let ref = Storage.storage().reference(forURL: mediaURL.absoluteString)
                        ref.delete { error in
                            if let error = error {
                                print("Failed to delete photo: \(error)")
                            } else {
                                print("Photo successfully deleted from Firebase.")
                            }
                            // Navigate back to camera
                            navigateToCameraView = true
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 22))           // Size = 22 points
                            .foregroundColor(.white)          // White icon
                            .padding(8)                       // Extra padding around icon
                            .background(
                                Circle().fill(Color.black.opacity(0.5))
                            )                                  // Semi-transparent black circle
                    }
                    .padding(.leading, 16)

                    Spacer()
                }

                Spacer()
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
        }
        // Present CameraView full screen when navigateToCameraView is true
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
