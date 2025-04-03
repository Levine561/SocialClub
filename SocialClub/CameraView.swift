import SwiftUI
import UIKit
import AVFoundation

struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var camera = CameraModel()
    @State private var showExploreView: Bool = false
    @State private var showPhotoConfirmation: Bool = false
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(camera: camera)
                .ignoresSafeArea(.all, edges: .all)
            
            // Shutter button at the bottom (recording)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 90, height: 90)
                        .onTapGesture {
                            camera.takePhoto()
                        }
                    Spacer()
                }
                .padding(.bottom, 40)
            }
            
            // Dismiss button at the top left
            VStack {
                HStack {
                    Button(action: {
                        showExploreView = true
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(.leading, 12)
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
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(8)
                        }
                        Divider()
                            .background(Color.white)
                        Button(action: {
                            camera.flipCamera()
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(4)
                        }
                    }
                    .padding(8)
                    .frame(width: 50)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                    .padding(.trailing, 4)
                }
                Spacer()
            }
            .padding(.top, 8)
            .offset(x: -10, y: 0)
        }
        .onChange(of: camera.capturedMediaURL) { newValue in
            if newValue != nil {
                showPhotoConfirmation = true
            }
        }
        .fullScreenCover(isPresented: $showPhotoConfirmation, onDismiss: {
            // Optionally, reset the captured media after dismissal
            camera.capturedMediaURL = nil
        }) {
            PhotoConfirmationView(mediaURL: camera.capturedMediaURL!)
        }
        .onAppear {
            camera.checkPermissions()
            camera.configure()
        }
        .fullScreenCover(isPresented: $showExploreView) {
            ExploreView()
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
    @Published var capturedMediaURL: URL? = nil
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
        session.startRunning()
    }
    
    func takePhoto() {
        print("Take photo button pressed")
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        settings.flashMode = flashEnabled ? .on : .off
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
        print("photoOutput delegate method called")
        guard let data = photo.fileDataRepresentation() else {
            print("Failed to get photo data")
            return
        }
        if let image = UIImage(data: data), let jpegData = image.jpegData(compressionQuality: 1.0) {
            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("capturedPhoto.jpg")
            do {
                try jpegData.write(to: fileURL)
                DispatchQueue.main.async {
                    self.capturedMediaURL = fileURL
                }
                print("Photo captured and saved to \(fileURL)")
            } catch {
                print("Error saving photo: \(error)")
            }
        }
    }
}

#Preview {
    CameraView()
}
