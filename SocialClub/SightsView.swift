import SwiftUI

struct SightsView: View {
    var photo: Photo
    @Environment(\.dismiss) var dismiss
    @State private var offsetY: CGFloat = 0
    @State private var navigateToExplore = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .topLeading) {
                Color.black.edgesIgnoringSafeArea(.all)

                AsyncImage(url: URL(string: photo.mediaURL)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .edgesIgnoringSafeArea(.all)
                    } else if phase.error != nil {
                        Color.red
                    } else {
                        ProgressView()
                    }
                }

                if let userProfileURL = photo.userProfileURL {
                    AsyncImage(url: URL(string: userProfileURL)) { phase in
                        if let image = phase.image {
                            image.resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 5)
                                .padding()
                        } else if phase.error != nil {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 48, height: 48)
                                .padding()
                        } else {
                            ProgressView().frame(width: 48, height: 48).padding()
                        }
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offsetY = value.translation.height
                    }
                    .onEnded { value in
                        if offsetY > 100 {
                            navigateToExplore = true
                        }
                        offsetY = 0
                    }
            )
            .background(
                NavigationLink(destination: ExploreView(), isActive: $navigateToExplore) {
                    EmptyView()
                }
            )
            .overlay(
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .foregroundColor(.white)
                    }
                }
                .padding(), alignment: .topTrailing
            )
        }
    }
}

#Preview {
    SightsView(photo: Photo(id: "1", mediaURL: "https://example.com/photo.jpg", userProfileURL: "https://example.com/profile.jpg", overlayText: nil, coordinate: nil))
}
