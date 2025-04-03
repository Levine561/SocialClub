//
//  PhotoConfirmationView.swift
//  SocialClub
//
//  Created by Matthew Levine on 4/1/25.
//

import SwiftUI
import AVKit

struct PhotoConfirmationView: View {
    let mediaURL: URL
    
    @Environment(\.dismiss) var dismiss
    @State private var postCopy: String = ""
    @State private var navigateToCameraView: Bool = false
    
    var body: some View {
        VStack {
            NavigationLink(destination: CameraView(), isActive: $navigateToCameraView) {
                EmptyView()
            }
            
            // Navigation bar with back arrow
            HStack {
                Button(action: {
                    navigateToCameraView = true
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title)
                        .padding()
                }
                Spacer()
            }
            
            // Display media
            if isImage {
                if let uiImage = UIImage(contentsOfFile: mediaURL.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .clipped()
                } else {
                    Text("Unable to load image")
                }
            } else {
                VideoPlayer(player: AVPlayer(url: mediaURL))
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 300)
            }
            
            // Text editor for post copy
            TextEditor(text: $postCopy)
                .frame(height: 100)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal)
            
            // Confirmation button
            Button(action: {
                // Process the confirmation (e.g., upload post with copy)
                print("Post confirmed with copy: \(postCopy)")
                dismiss()
            }) {
                Text("Confirm")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            
            Spacer()
        }
        .navigationBarHidden(true)
    }
    
    var isImage: Bool {
        let ext = mediaURL.pathExtension.lowercased()
        return ext == "jpg" || ext == "jpeg" || ext == "png"
    }
}

#Preview {
    PhotoConfirmationView(mediaURL: URL(string: "https://example.com/image.jpg")!)
}
