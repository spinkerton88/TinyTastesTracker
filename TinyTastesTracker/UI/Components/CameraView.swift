//
//  CameraView.swift
//  TinyTastesTracker
//
//  AI Camera Capture for Food Identification
//

import SwiftUI
import AVFoundation
import UIKit

//
//  CameraView.swift
//  TinyTastesTracker
//
//  AI Camera Capture for Food Identification
//

import SwiftUI
import AVFoundation
import UIKit

// NEW: Main SwiftUI Camera View with standardized overlay
struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    
    let title: String
    let subtitle: String?
    let iconName: String
    var showsCancelButton: Bool = true // Kept for API compatibility, though handled by overlay
    let onCapture: (UIImage) -> Void
    
    // Default initializer for backward compatibility
    init(
        title: String = "Take Photo",
        subtitle: String? = nil,
        iconName: String = "camera.viewfinder",
        showsCancelButton: Bool = true,
        onCapture: @escaping (UIImage) -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.showsCancelButton = showsCancelButton
        self.onCapture = onCapture
    }
    
    // Internal state for triggering capture
    @State private var shutterAction: (() -> Void)?
    
    var body: some View {
        ZStack {
            // Camera Preview (UIKit)
            CameraPreviewView(onCapture: onCapture) { action in
                shutterAction = action
            }
            .ignoresSafeArea()
            
            // Standard Unified Overlay
            CameraOverlayView(
                title: title,
                subtitle: subtitle,
                iconName: iconName,
                onClose: { dismiss() }
            )
            
            // Capture Button
            VStack {
                Spacer()
                Button {
                    HapticManager.impact(style: .medium)
                    shutterAction?()
                } label: {
                    Circle()
                        .strokeBorder(.white, lineWidth: 4)
                        .background(Circle().fill(.white.opacity(0.2)))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .fill(.white)
                                .frame(width: 64, height: 64)
                        )
                        .shadow(radius: 10)
                }
                .padding(.bottom, 160) // Position above the text card
            }
        }
    }
}

// Renamed from CameraView to CameraPreviewView
// Removed internal UI/Overlay logic to be pure preview + logic
struct CameraPreviewView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    let registerShutter: (@escaping () -> Void) -> Void
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.onCapture = onCapture
        
        // Pass the controller's capture method back to SwiftUI view
        registerShutter { [weak controller] in
            controller?.capturePhoto()
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController {
    var captureSession: AVCaptureSession?
    var photoOutput: AVCapturePhotoOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?

    var onCapture: ((UIImage) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        // No UI setup here anymore - pure camera logic
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        
        captureSession.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            // Error handling can optionally be propagated or handled gracefully
            return
        }
        
        photoOutput = AVCapturePhotoOutput()
        guard let photoOutput = photoOutput else { return }

        if captureSession.canAddInput(input) && captureSession.canAddOutput(photoOutput) {
            captureSession.addInput(input)
            captureSession.addOutput(photoOutput)
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = view.bounds
            
            if let previewLayer = previewLayer {
                view.layer.addSublayer(previewLayer)
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
            }
        }
    }
    
    func capturePhoto() {
        guard let photoOutput = photoOutput else { return }
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // Removed prompt logic, internal buttons, etc.
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }
        
        captureSession?.stopRunning()
        onCapture?(image)
    }
}
