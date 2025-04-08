import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore

struct Photo: Identifiable {
    var id: String
    var mediaURL: String
    var overlayText: String?
    var coordinate: CLLocationCoordinate2D?
}
class PhotoAnnotation: MKPointAnnotation {
    var photo: Photo?
}

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
    @State private var photos: [Photo] = []

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

    private func loadPhotos() {
        let db = Firestore.firestore()
        db.collection("photos").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching photos: \(error)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            var fetchedPhotos: [Photo] = []
            for doc in documents {
                let data = doc.data()
                let mediaURL = data["mediaURL"] as? String ?? ""
                let overlayText = data["overlayText"] as? String
                var coordinate: CLLocationCoordinate2D? = nil
                if let locationString = data["location"] as? String {
                    let parts = locationString.split(separator: ",")
                    if parts.count == 2,
                       let lat = Double(parts[0]),
                       let lon = Double(parts[1]) {
                        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    }
                }
                let photo = Photo(id: doc.documentID, mediaURL: mediaURL, overlayText: overlayText, coordinate: coordinate)
                fetchedPhotos.append(photo)
            }
            DispatchQueue.main.async {
                self.photos = fetchedPhotos
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
                    ThreeDMapView(region: $region, resetCamera: $resetCamera, userHeading: userHeading, photos: photos)
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
                                placeholders: 5,
                                photos: photos
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
                    loadPhotos()
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
    var photos: [Photo]? = nil

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

            // Horizontal scroll of images or placeholders
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if title == "Sights" {
                        // For Sights, always show at least 5 items
                        let photoCount = photos?.count ?? 0
                        if let photos = photos, !photos.isEmpty {
                            ForEach(photos) { photo in
                                AsyncImage(url: URL(string: photo.mediaURL)) { phase in
                                    if let image = phase.image {
                                        image.resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120 * 16 / 9.0)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    } else if phase.error != nil {
                                        // Display an error placeholder
                                        Color.red
                                            .frame(width: 120, height: 120 * 16 / 9.0)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    } else {
                                        SkeletonRectangleView(cornerRadius: 6)
                                            .frame(width: 120, height: 120 * 16 / 9.0)
                                    }
                                }
                            }
                        }
                        let placeholdersToShow = max(0, 5 - (photoCount))
                        ForEach(0..<placeholdersToShow, id: \.self) { _ in
                            SkeletonRectangleView(cornerRadius: 6)
                                .frame(width: 120, height: 120 * 16 / 9.0)
                        }
                    } else {
                        // For other sections, use previous logic
                        if let photos = photos, !photos.isEmpty {
                            ForEach(photos) { photo in
                                AsyncImage(url: URL(string: photo.mediaURL)) { phase in
                                    if let image = phase.image {
                                        image.resizable()
                                            .scaledToFill()
                                            .frame(width: 140, height: 140)
                                            .clipped()
                                    } else if phase.error != nil {
                                        // Display an error placeholder
                                        Color.red
                                            .frame(width: 140, height: 140)
                                    } else {
                                        SkeletonRectangleView(cornerRadius: 6)
                                            .frame(width: 140, height: 140)
                                    }
                                }
                            }
                        } else {
                            ForEach(0..<placeholders, id: \.self) { _ in
                                SkeletonRectangleView(cornerRadius: 6)
                                    .frame(width: 140, height: 140)
                            }
                        }
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

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
    static var imageCache = NSCache<NSString, UIImage>()
    
    var parent: ThreeDMapView
    init(_ parent: ThreeDMapView) {
        self.parent = parent
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let scaleFactor = max(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        let rect = CGRect(x: (targetSize.width - newSize.width) / 2,
                          y: (targetSize.height - newSize.height) / 2,
                          width: newSize.width,
                          height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? image
    }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Use default view for user location
            if annotation is MKUserLocation {
                return nil
            }
            
            if let photoAnnotation = annotation as? PhotoAnnotation {
                let identifier = "PhotoMarker"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                // Set up annotation view appearance as a circular image with an outline
                annotationView?.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
                annotationView?.layer.cornerRadius = 25
                annotationView?.layer.borderWidth = 2
                annotationView?.layer.borderColor = UIColor.white.cgColor
                annotationView?.clipsToBounds = true
                annotationView?.contentMode = .scaleAspectFill
                // Set a placeholder image while loading
                annotationView?.image = UIImage(systemName: "photo")
                
                if let urlString = photoAnnotation.photo?.mediaURL, let url = URL(string: urlString) {
                    if let cachedImage = Coordinator.imageCache.object(forKey: urlString as NSString) {
                        annotationView?.image = cachedImage
                    } else {
                        // Set placeholder image
                        annotationView?.image = UIImage(systemName: "photo")
                        let currentAnnotationView = annotationView
                        URLSession.shared.dataTask(with: url) { data, response, error in
                            if let data = data, let image = UIImage(data: data) {
                                // Resize image to fit within 50x50 bounds
                                let targetSize = CGSize(width: 50, height: 50)
                                let resizedImage = self.resizeImage(image: image, targetSize: targetSize)
                                // Cache the resized image
                                Coordinator.imageCache.setObject(resizedImage, forKey: urlString as NSString)
                                DispatchQueue.main.async {
                                    if let currentPhotoAnnotation = currentAnnotationView?.annotation as? PhotoAnnotation,
                                       let currentMediaURL = currentPhotoAnnotation.photo?.mediaURL,
                                       currentMediaURL == urlString {
                                        currentAnnotationView?.image = resizedImage
                                        currentAnnotationView?.setNeedsDisplay()
                                    }
                                }
                            }
                        }.resume()
                    }
                }
                return annotationView
            }
            return nil
        }
    }
    var photos: [Photo]  // New property for photo markers

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
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
            let camera = MKMapCamera(lookingAtCenter: region.center, fromDistance: computedAltitude, pitch: 60, heading: userHeading)
            uiView.setCamera(camera, animated: true)
            DispatchQueue.main.async {
                self.resetCamera = false
            }
        }
        
        // Remove existing annotations
        uiView.removeAnnotations(uiView.annotations)
        
        // Add custom photo annotations
        for photo in photos {
            if let coordinate = photo.coordinate {
                let annotation = PhotoAnnotation()
                annotation.coordinate = coordinate
                annotation.title = photo.overlayText ?? "Photo"
                annotation.photo = photo
                uiView.addAnnotation(annotation)
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
