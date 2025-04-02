import SwiftUI
import AVFoundation

struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var camera = CameraModel()
    @State private var showExploreView: Bool = false
    @State private var isRecording: Bool = false
    @State private var recordingProgress: CGFloat = 0.0
    @State private var recordingTimer: Timer? = nil
    
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
                        .fill(isRecording ? Color.red : Color.clear)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white, lineWidth: 4)
                        )
                        .frame(width: 90, height: 90)
                        .overlay(
                            Circle()
                                .trim(from: 0, to: recordingProgress)
                                .stroke(Color.red, lineWidth: 4)
                                .rotationEffect(.degrees(-90))
                        )
                        .gesture(
                            LongPressGesture(minimumDuration: 0.1)
                                .onChanged { _ in
                                    if !isRecording {
                                        isRecording = true
                                        recordingProgress = 0.0
                                        camera.startRecording()
                                        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                                            recordingProgress += 0.01
                                            if recordingProgress >= 1.0 {
                                                isRecording = false
                                                recordingTimer?.invalidate()
                                                recordingTimer = nil
                                                camera.stopRecording()
                                            }
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    if isRecording {
                                        isRecording = false
                                        recordingTimer?.invalidate()
                                        recordingTimer = nil
                                        camera.stopRecording()
                                    }
                                }
                        )
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
        let settings = AVCapturePhotoSettings()
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
    
    func startRecording() {
        // Start recording video (this is a stub for actual recording functionality)
        print("Recording started")
    }
    
    func stopRecording() {
        // Stop recording video (this is a stub for actual recording functionality)
        print("Recording stopped")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else { return }
        // Process photo data here (e.g., save to library or display the image)
        print("Photo captured: \(data.count) bytes")
    }
}

#Preview {
    CameraView()
}
