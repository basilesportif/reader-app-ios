import Foundation
import AVFoundation
import SwiftUI

@Observable
class CameraManager: NSObject {
    var isAuthorized = false
    var capturedImage: Data?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var photoContinuation: CheckedContinuation<Data?, Never>?
    
    override init() {
        super.init()
        checkAuthorization()
    }
    
    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.setupSession()
                    }
                }
            }
        default:
            isAuthorized = false
        }
    }
    
    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        session.commitConfiguration()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
    }
    
    func startSession() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func stopSession() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
    }
    
    func capturePhoto() async -> Data? {
        // Check if there's an active video connection (won't exist on simulator)
        guard photoOutput.connection(with: .video) != nil else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            self.photoContinuation = continuation

            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto

            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func clearCapturedImage() {
        capturedImage = nil
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let imageData = photo.fileDataRepresentation()
        
        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = imageData
            self?.photoContinuation?.resume(returning: imageData)
            self?.photoContinuation = nil
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        if let previewLayer = cameraManager.previewLayer {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            cameraManager.previewLayer?.frame = uiView.bounds
        }
    }
}
