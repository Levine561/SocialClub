import SwiftUI
import UIKit
import AVFoundation
import FirebaseStorage
import AudioToolbox

struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var camera = CameraModel()
    @State private var showExploreView: Bool = false
    @State private var showPhotoConfirmationView: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Camera preview
                CameraPreview(camera: camera)
                    .ignoresSafeArea(.all, edges: .all)
                
                // Shutter button at the bottom (recording)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ShutterButton(action: {
                            print("Shutter button tapped")
                            camera.takePhoto()
                        })
                        Spacer()
                    }
                    .padding(.bottom, 12)
                }
                
                // Dismiss button at the top left
                VStack {
                    HStack {
                        Button(action: {
                            showExploreView = true
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .padding(.leading, 16)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 4)
                
                // Flash and Camera Flip buttons container
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Button(action: {
                                camera.toggleFlash()
                            }) {
                                Image(systemName: camera.flashEnabled ? "bolt" : "bolt.slash")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                    .padding(8)
                            }
                            Divider()
                                .background(Color.white)
                            Button(action: {
                                camera.flipCamera()
                            }) {
                                Image(systemName: "arrow.triangle.2.circlepath.camera")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                    .padding(5)
                            }
                        }
                        .padding(8)
                        .frame(width: 45)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                    }
                    Spacer()
                }
                .padding(.top, 4)
                .padding(.horizontal, 16)
            }
            .onAppear {
                camera.checkPermissions()
                camera.configure()
            }
            .onReceive(camera.$capturedImage) { newImage in
                if newImage != nil {
                    showPhotoConfirmationView = true
                }
            }
            .fullScreenCover(isPresented: $showExploreView) {
                ExploreView()
            }
            .fullScreenCover(isPresented: $showPhotoConfirmationView) {
                if let image = camera.capturedImage, let url = camera.mediaURL {
                    PhotoConfirmationView(image: image, mediaURL: url)
                }
            }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        camera.previewLayer.frame = view.bounds
        view.layer.addSublayer(camera.previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var flashEnabled: Bool = false
    var currentCameraPosition: AVCaptureDevice.Position = .back
    @Published var session = AVCaptureSession()
    @Published var output = AVCapturePhotoOutput()
    @Published var capturedImage: UIImage? = nil
    @Published var mediaURL: URL? = nil
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()
    
    override init() {
        super.init()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.configure()
                    }
                }
            }
        default:
            return
        }
    }
    
    func configure() {
        session.beginConfiguration()
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition) else {
            session.commitConfiguration()
            return
        }
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
        
        if let connection = output.connection(with: .video),
           connection.isVideoMirroringSupported,
           currentCameraPosition == .front {
            connection.isVideoMirrored = false
        }
        
        session.startRunning()
    }
    
    func playShutterSound() {
        AudioServicesPlaySystemSound(1108)
    }
    
    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        if flashEnabled, output.supportedFlashModes.contains(.on) {
            settings.flashMode = .on
        } else {
            settings.flashMode = .off
        }

        playShutterSound()
        output.capturePhoto(with: settings, delegate: self)
    }
    
    func toggleFlash() {
        flashEnabled.toggle()
        print("Flash is now \(flashEnabled ? "On" : "Off")")
    }
    
    func flipCamera() {
        session.beginConfiguration()
        // Remove existing inputs
        for input in session.inputs {
            session.removeInput(input)
        }
        // Toggle camera position
        currentCameraPosition = (currentCameraPosition == .back) ? .front : .back
        // Get new camera device
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }
        if session.canAddInput(input) {
            session.addInput(input)
        }
        session.commitConfiguration()
        print("Camera flipped to \(currentCameraPosition == .back ? "Back" : "Front")")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        print("Photo capture delegate called")
        // Update the capturedImage
        DispatchQueue.main.async {
            self.capturedImage = image
        }
        // Upload to Firebase
        let storageRef = Storage.storage().reference().child("images/\(UUID().uuidString).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Failed to upload: \(error)")
                return
            }
            print("Image uploaded successfully!")
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Failed to get download URL: \(error)")
                    return
                }
                if let url = url {
                    DispatchQueue.main.async {
                        self.mediaURL = url
                    }
                }
            }
        }
    }
}

struct ShutterButton: View {
    let action: () -> Void
    @GestureState private var isPressed: Bool = false
    
    var body: some View {
        let pressGesture = LongPressGesture(minimumDuration: 0.01)
            .updating($isPressed) { currentState, state, _ in
                state = currentState
            }
            .onEnded { _ in
                action()
            }
        
        return ZStack {
            Circle()
                .stroke(Color.white, lineWidth: 4)
                .frame(width: 100, height: 100)
            Circle()
                .fill(Color.white)
                .frame(width: 80, height: 80)
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .gesture(pressGesture)
    }
}

#Preview {
    CameraView()
}
