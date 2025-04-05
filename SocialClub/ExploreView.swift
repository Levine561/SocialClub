import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore

extension Color {
    static var adaptiveBackground: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                // Dark mode: a darker translucent background
                return UIColor(red: 40/255, green: 40/255, blue: 40/255, alpha: 0.8)
            } else {
                // Light mode: use the F4F7F8 color with translucency
                return UIColor(red: 244/255, green: 247/255, blue: 248/255, alpha: 0.8)
            }
        })
    }
}
 
struct SkeletonCircleView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var animationOffset: CGFloat = -100  // initial offset
    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                GeometryReader { geometry in
                    let gradientWidth = geometry.size.width * 1.5
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.white.opacity(colorScheme == .dark ? 0.1 : 0.25), Color.clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: gradientWidth)
                        .offset(x: animationOffset)
                        .onAppear {
                            animationOffset = -gradientWidth
                            withAnimation(Animation.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                                animationOffset = geometry.size.width
                            }
                        }
                }
            )
            .clipShape(Circle())
    }
}

struct SkeletonRectangleView: View {
    var cornerRadius: CGFloat = 6
    @Environment(\.colorScheme) var colorScheme
    @State private var animationOffset: CGFloat = -100  // initial offset
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                GeometryReader { geometry in
                    let gradientWidth = geometry.size.width * 1.5
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                        LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.white.opacity(colorScheme == .dark ? 0.1 : 0.25), Color.clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: gradientWidth)
                        .offset(x: animationOffset)
                        .onAppear {
                            animationOffset = -gradientWidth
                            withAnimation(Animation.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                                animationOffset = geometry.size.width
                            }
                        }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocation?  // Published location property
    @Published var heading: CLLocationDirection = 0
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Request permission and start updating location
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.heading = newHeading.trueHeading
        }
    }
    
    // Update the published currentLocation whenever new data is available
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location
        }
    }
}

struct ExploreView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), // Placeholder; will update to user's location automatically
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @StateObject private var locationManager = LocationManager()
    @State private var profileImage: UIImage? = nil
    @State private var showLocationModal: Bool = true
    @State private var showCameraView = false
    @State private var showProfileView: Bool = false
    @State private var resetCamera: Bool = false
    @State private var userHeading: CLLocationDirection = 0

    private func loadProfileImage() {
        guard let currentUser = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        db.collection("users").document(currentUser.uid).getDocument { snapshot, error in
            if let data = snapshot?.data(), let urlString = data["profilePictureURL"] as? String, let url = URL(string: urlString) {
                URLSession.shared.dataTask(with: url) { data, response, error in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.profileImage = image
                        }
                    }
                }.resume()
            }
        }
    }

    var body: some View {
        Group {
            if locationManager.currentLocation == nil {
                // Show a loading indicator while waiting for location
                VStack {
                    Spacer()
                    ProgressView("Getting current location...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.adaptiveBackground)
            } else {
                // Once location is available, update region and show the map and UI
                ZStack(alignment: .top) {
                    // 3D Map (simplified)
                    ThreeDMapView(region: $region, resetCamera: $resetCamera, userHeading: userHeading)
                        .edgesIgnoringSafeArea(.all)
                    
                    // Blur overlay at top for improved readability of status bar content
                    VStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .frame(height: 50)
                            .mask(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white, Color.clear]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        Spacer()
                    }
                    .edgesIgnoringSafeArea(.top)

                    // Profile image and search/location container (moved from overlay)
                    HStack(alignment: .top) {
                        if let profileImage = profileImage {
                        Button(action: {
                            withAnimation(nil) {
                                showProfileView = true
                            }
                        }) {
                                ZStack {
                                    // Container 4 px larger than the profile image with the same style as the top right-hand rail
                                    Circle()
                                        .fill(.regularMaterial)
                                        .frame(width: 68, height: 68)
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 64)
                                        .clipShape(Circle())
                                }
                            }
                            .buttonStyle(PressableButtonStyle())
                        } else {
                            Button(action: {
                                showProfileView = true
                            }) {
                                SkeletonCircleView()
                                    .frame(width: 68, height: 68)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }

                        Spacer()
                        VStack(spacing: 8) {
                            // Search and location container
                            VStack(spacing: 8) {
                                Button(action: {
                                    // Search action
                                }) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.title2)
                                        .frame(width: 45, height: 45)
                                }
                                .buttonStyle(PressableButtonStyle())

                                Divider()
                                    .frame(width: 40)
                                    .background(Color.primary)
                                    .padding(.vertical, 0)

                                Button(action: {
                                    if let location = locationManager.currentLocation {
                                        region.center = location.coordinate
                                        resetCamera = true
                                    }
                                }) {
                                    Image(systemName: "location")
                                        .font(.title2)
                                        .frame(width: 45, height: 45)
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                            .padding(0)
                            .background(RoundedRectangle(cornerRadius: 8).fill(.regularMaterial))

                            // Camera button in a circle container
                            Button(action: {
                                withAnimation(nil) {
                                    showCameraView = true
                                }
                            }) {
                                Image(systemName: "camera")
                                    .font(.title2)
                                    .frame(width: 45, height: 45)
                                    .background(Circle().fill(.regularMaterial))
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .zIndex(0)

                    // Pull-up bottom sheet
                    BottomSheetView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Sights
                            SectionView(
                                title: "Sights",
                                subtitle: "See what's happening near you",
                                placeholders: 5
                            )

                            // Hotspots
                            SectionView(
                                title: "Hotspots",
                                subtitle: "Explore and discover your area",
                                placeholders: 5
                            )

                            // Clubs
                            SectionView(
                                title: "Clubs",
                                subtitle: "Chat with your community",
                                placeholders: 5
                            )

                            // Bottom label
                            HStack {
                                Spacer()
                                Text("Keep exploring!")
                                    .font(.footnote)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .zIndex(1)
                }
                .onReceive(locationManager.$currentLocation) { location in
                    if let location = location {
                        // Check if the region is still at the placeholder (0.0, 0.0)
                        if region.center.latitude == 0.0 && region.center.longitude == 0.0 {
                            region.center = location.coordinate
                            resetCamera = true
                        }
                    }
                }
                .onReceive(locationManager.$heading) { newHeading in
                    userHeading = newHeading
                }
                .onAppear {
                    loadProfileImage()
                    // Additional onAppear actions if needed
                }
                .fullScreenCover(isPresented: $showCameraView) {
                    CameraView()
                }
                .fullScreenCover(isPresented: $showProfileView) {
                    ProfileView()
                }
            }
        }
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
    }
}

// MARK: - SectionView

/// Displays a section header with a dropdown and a horizontal scroll of blank images
struct SectionView: View {
    let title: String
    let subtitle: String
    let placeholders: Int

    // Dropdown
    @State private var selectedOption = "Hottest"
    let menuOptions = ["Nearest", "For you", "Hottest"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title + Dropdown
            HStack {
                Text(title)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.primary)

                Spacer()
                
                Menu {
                    ForEach(menuOptions, id: \.self) { option in
                        Button(option) {
                            selectedOption = option
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedOption)
                            .font(.subheadline)
                            .foregroundColor(Color(red: 55/255.0, green: 119/255.0, blue: 1.0))
                        Image(systemName: "chevron.down")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 55/255.0, green: 119/255.0, blue: 1.0))
                    }
                }
            }

            // Subtitle
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Horizontal scroll of placeholder images
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<placeholders, id: \.self) { _ in
                        // Blank image placeholder
                        SkeletonRectangleView(cornerRadius: 6)
                            .frame(width: title == "Sights" ? 120 : 140,
                                   height: title == "Sights" ? 120 * 16 / 9.0 : 140)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - ThreeDMapView (Minimal)

/// A minimal UIViewRepresentable that displays a standard MKMapView
struct ThreeDMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var resetCamera: Bool
    var userHeading: CLLocationDirection

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.showsCompass = false
        mapView.showsUserLocation = true
        mapView.pointOfInterestFilter = MKPointOfInterestFilter.excludingAll
        mapView.showsBuildings = true
        mapView.isScrollEnabled = true    // Enables panning
        mapView.isRotateEnabled = true    // Allow rotation
        mapView.isPitchEnabled = true     // Locks the camera pitch
        
        let computedAltitude = max(500, min(2000, region.span.latitudeDelta * 111000))
        let camera = MKMapCamera(lookingAtCenter: region.center, fromDistance: computedAltitude, pitch: 60, heading: userHeading)
        mapView.setCamera(camera, animated: false)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if resetCamera {
            let computedAltitude = max(500, min(2000, region.span.latitudeDelta * 111000))
            // Use the current heading or a default value
            let camera = MKMapCamera(lookingAtCenter: region.center, fromDistance: computedAltitude, pitch: 60, heading: userHeading)
            uiView.setCamera(camera, animated: true)
            DispatchQueue.main.async {
                self.resetCamera = false
            }
        }
    }
}

// MARK: - BottomSheetView

/// A simple draggable bottom sheet with a "handle" at the top and a content area.
struct BottomSheetView<Content: View>: View {
    @GestureState private var dragOffset: CGFloat = 0
    @State private var offset: CGFloat = UIScreen.main.bounds.height / 2  // Start half-open
    
    let content: () -> Content
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Top handle
                Capsule()
                    .fill(Color.secondary)
                    .frame(width: 40, height: 6)
                    .padding(.vertical, 12)
                
                // Content passed in from the caller
                content()
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .background(.regularMaterial)
            .cornerRadius(16)
            .offset(y: offset + dragOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        // Track drag in real-time
                        state = value.translation.height
                    }
                    .onEnded { value in
                        // Decide where to settle the sheet after the drag
                        let totalOffset = offset + value.translation.height
                        let upperBound = geo.size.height * 0.2  // Fully open
                        let lowerBound = geo.size.height * 0.8  // Mostly closed
                        
                        if totalOffset < upperBound {
                            offset = 0
                        } else if totalOffset > lowerBound {
                            offset = lowerBound
                        } else {
                            offset = geo.size.height / 2
                        }
                    }
            )
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
