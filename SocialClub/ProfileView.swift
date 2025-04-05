//
//  ProfileView.swift
//  SocialClub
//
//  Created by Matthew Levine on 4/2/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var profileImageURL: String? = nil
    @State private var showOptions: Bool = false
    @State private var shouldShowLoginView: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var name: String = ""
    @State private var username: String = ""
    @State private var showExploreView: Bool = false
    @Environment(\.presentationMode) var presentationMode

    private func loadProfileImage() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                if let url = document.get("profilePictureURL") as? String {
                    DispatchQueue.main.async {
                        self.profileImageURL = url
                    }
                }
                if let fetchedName = document.get("name") as? String {
                    DispatchQueue.main.async {
                        self.name = fetchedName
                    }
                }
                if let fetchedUsername = document.get("username") as? String {
                    DispatchQueue.main.async {
                        self.username = fetchedUsername
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Sticky Header
            ZStack {
                // Centered username in header
                Text(name.isEmpty ? "Loading..." : name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                // HStack for X and Ellipsis buttons
                HStack {
                    // X Button that opens ExploreView with 16px left padding
                    Button(action: {
                        showExploreView = true
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(colorScheme == .light ? .black : .white)
                    }
                    .padding(.leading, 16)
                    Spacer()
                    // Ellipsis Button for options with 16px right padding
                    Button(action: {
                        showOptions.toggle()
                    }) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(colorScheme == .light ? .black : .white)
                            .padding(8)
                            .background(Color(UIColor.systemBackground).opacity(0.7))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                }
            }
            .frame(height: 44)
            .background(Color(UIColor.systemBackground))
            
            // Scrollable Content
            ScrollView {
                VStack(spacing: 4) {
                    // Profile Image Row (without overlay)
                    if let urlString = profileImageURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                 .aspectRatio(contentMode: .fill)
                                 .frame(width: 90, height: 90)
                                 .clipShape(Circle())
                        } placeholder: {
                            SkeletonView()
                        }
                    } else {
                        SkeletonView()
                    }
                    
                    // Full Name below profile image
                    Text(username.isEmpty ? "@loading" : "@\(username)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                    
                    // Edit Profile Button
                    Button(action: {
                        // TODO: Add edit profile functionality
                    }) {
                        Text("Edit profile")
                            .font(.body)
                            .foregroundColor(colorScheme == .light ? .black : .white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(colorScheme == .light ? Color(hex: "F3F2F8") : Color(hex: "242427"))
                            .cornerRadius(8)
                    }
                    .padding(.top, 16)
                    
                    // Grid of photo placeholders
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2)
                    ], spacing: 2) {
                        ForEach(0..<12) { index in
                            Rectangle()
                                .fill(Color(UIColor.secondarySystemFill))
                                .frame(height: 200)
                        }
                    }
                    .padding(.top, 16)
                    
                    Spacer()
                }
                .padding(.top, 16)
            }
        }
        .onAppear {
            loadProfileImage()
        }
        .navigationBarHidden(true) // hide default navigation bar
        .fullScreenCover(isPresented: $shouldShowLoginView) {
            LoginView()
        }
        .fullScreenCover(isPresented: $showExploreView) {
            ExploreView()
        }
        .actionSheet(isPresented: $showOptions) {
            ActionSheet(title: Text("Settings"), message: nil, buttons: [
                .default(Text("Logout"), action: {
                    do {
                        try Auth.auth().signOut()
                        shouldShowLoginView = true
                    } catch {
                        print("Error signing out: \(error)")
                    }
                }),
                .destructive(Text("Delete Account"), action: {
                    guard let user = Auth.auth().currentUser else { return }
                    let userID = user.uid

                    let db = Firestore.firestore()
                    let storageRef = Storage.storage().reference().child("profilePictures/\(userID).jpg")

                    // Delete user's profile picture from Storage
                    storageRef.delete { storageError in
                        if let storageError = storageError {
                            print("Error deleting Storage data: \(storageError)")
                        } else {
                            print("Storage file deleted")
                        }

                        // Delete user's Firestore document
                        db.collection("users").document(userID).delete { firestoreError in
                            if let firestoreError = firestoreError {
                                print("Error deleting Firestore data: \(firestoreError)")
                            } else {
                                print("Firestore data deleted")
                            }

                            // Delete user's Auth account
                            user.delete { authError in
                                if let authError = authError {
                                    print("Error deleting account: \(authError)")
                                } else {
                                    shouldShowLoginView = true
                                }
                            }
                        }
                    }
                }),
                .cancel(Text("Cancel"))
            ])
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Are you sure?"),
                message: Text("This will permanently delete your account."),
                primaryButton: .destructive(Text("Delete Account"), action: {
                    guard let user = Auth.auth().currentUser else { return }
                    let userID = user.uid

                    // Delete user's Firestore document
                    let db = Firestore.firestore()
                    db.collection("users").document(userID).delete { error in
                        if let error = error {
                            print("Error deleting Firestore data: \(error)")
                        } else {
                            print("Firestore data deleted")
                        }
                    }

                    // Delete user's profile picture from Storage
                    let storageRef = Storage.storage().reference().child("profilePictures/\(userID).jpg")
                    storageRef.delete { error in
                        if let error = error {
                            print("Error deleting Storage data: \(error)")
                        } else {
                            print("Storage file deleted")
                        }
                    }

                    // Delete user's Auth account
                    user.delete { error in
                        if let error = error {
                            print("Error deleting account: \(error)")
                        } else {
                            shouldShowLoginView = true
                        }
                    }
                }),
                secondaryButton: .cancel()
            )
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        self.init(
            .sRGB,
            red: Double((rgbValue & 0xff0000) >> 16) / 255,
            green: Double((rgbValue & 0x00ff00) >> 8) / 255,
            blue: Double(rgbValue & 0x0000ff) / 255,
            opacity: 1.0
        )
    }
}

struct SkeletonView: View {
    @State private var isAnimating: Bool = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 45)
            .fill(Color(white: 0.85))
            .frame(width: 90, height: 90)
            .opacity(isAnimating ? 0.5 : 1.0)
            .onAppear {
                withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: true)) {
                    isAnimating.toggle()
                }
            }
    }
}

struct HidesBarsOnSwipe: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        DispatchQueue.main.async {
            viewController.navigationController?.hidesBarsOnSwipe = true
        }
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

extension View {
    func hidesBarsOnSwipe() -> some View {
        self.background(HidesBarsOnSwipe())
    }
}

#Preview {
    NavigationView {
        ProfileView()
    }
}
