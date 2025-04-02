import SwiftUI
import MapKit

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

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocation?  // Published location property
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Request permission and start updating location
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
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
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Example: San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @StateObject private var locationManager = LocationManager()
    @State private var profileImage: UIImage? = nil
    @State private var showLocationModal: Bool = true
    @State private var showCameraView = false

    var body: some View {
        ZStack(alignment: .top) {
            // 3D Map (simplified)
            ThreeDMapView(region: $region)
                .edgesIgnoringSafeArea(.all)

            // Profile image and search/location container (moved from overlay)
            HStack(alignment: .top) {
                // Profile image on the top left as button
                if let profileImage = profileImage {
                    Button(action: {
                        // Profile tapped action
                    }) {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PressableButtonStyle())
                } else {
                    Button(action: {
                        // Profile tapped action
                    }) {
                        ZStack {
                            Circle()
                                .fill(.regularMaterial)
                                .frame(width: 64, height: 64)
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 70, height: 60)
                                .foregroundColor(.secondary)
                        }
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
                                .frame(width: 50, height: 50)
                        }
                        .buttonStyle(PressableButtonStyle())
                        
                        Divider()
                            .frame(width: 40)
                            .background(Color.primary)
                            .padding(.vertical, 0)
                        
                        Button(action: {
                            // Reset the region to the user's current location when tapped
                            if let location = locationManager.currentLocation {
                                region.center = location.coordinate
                            }
                        }) {
                        Image(systemName: "location")
                                .font(.title2)
                                .frame(width: 50, height: 50)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                    .padding(0)
                    .background(RoundedRectangle(cornerRadius: 8).fill(.regularMaterial))
                    
                    // Camera button in a circle container
                    Button(action: {
                        showCameraView = true
                    }) {
                        Image(systemName: "camera")
                            .font(.title2)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(.regularMaterial))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding()
            .offset(y: -20)
            .zIndex(0)

            // Pull-up bottom sheet
            BottomSheetView {
                VStack(alignment: .leading, spacing: 24) {
                    // Sights
                    SectionView(
                        title: "Sights",
                        subtitle: "See whats happening near you",
                        placeholders: 5
                    )

                    // Hotspots
                    SectionView(
                        title: "Hotspots",
                        subtitle: "Attend events and activities",
                        placeholders: 5
                    )

                    // Communities
                    SectionView(
                        title: "Communities",
                        subtitle: "Join clubs and meet new people",
                        placeholders: 5
                    )

                    // Bottom label
                    HStack {
                        Spacer()
                        Text("Keep exploring!")
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
                region.center = location.coordinate
            }
        }
        .onAppear {
            // Additional onAppear actions if needed
        }
        .fullScreenCover(isPresented: $showCameraView) {
            CameraView()
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
    let menuOptions = ["Hottest", "Newest", "Nearest"]

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
                        Image(systemName: "chevron.down")
                            .font(.subheadline)
                    }.foregroundColor(.primary)
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
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: title == "Sights" ? 120 : 140,
                                   height: title == "Sights" ? 120 * 16 / 9.0 : 140)
                            .cornerRadius(6)
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

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.showsUserLocation = true
        mapView.showsBuildings = true
        mapView.isScrollEnabled = true    // Enables panning
        mapView.isRotateEnabled = true    // Allow rotation
        mapView.isPitchEnabled = false     // Locks the camera pitch
        
        
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Compute an altitude based on the region's span (rough conversion: 1 degree ~ 111,000 meters)
        let computedAltitude = max(500, min(2000, region.span.latitudeDelta * 111000))
        
        // Lock the camera with a fixed pitch (for 3D view) and heading
        let currentHeading = uiView.camera.heading
        let camera = MKMapCamera(lookingAtCenter: region.center, fromDistance: computedAltitude, pitch: 60, heading: currentHeading)
        uiView.setCamera(camera, animated: true)
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
