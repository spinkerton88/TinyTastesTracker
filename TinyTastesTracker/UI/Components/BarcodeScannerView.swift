//
//  BarcodeScannerView.swift
//  TinyTastesTracker
//
//  VisionKit-based barcode scanner for food products
//

import SwiftUI
import VisionKit

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onBarcodeScanned: (String) -> Void
    let onError: (Error) -> Void
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [
                .barcode(symbologies: [.upce, .ean8, .ean13, .code39, .code93, .code128, .qr])
            ],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // Start scanning if not already started
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcodeScanned: onBarcodeScanned, onError: onError)
    }
    
    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onBarcodeScanned: (String) -> Void
        let onError: (Error) -> Void
        private var hasScanned = false
        
        init(onBarcodeScanned: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
            self.onBarcodeScanned = onBarcodeScanned
            self.onError = onError
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            handleScannedItem(item)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // Auto-scan the first barcode detected
            guard !hasScanned, let item = addedItems.first else { return }
            handleScannedItem(item)
        }
        
        private func handleScannedItem(_ item: RecognizedItem) {
            guard !hasScanned else { return }
            
            switch item {
            case .barcode(let barcode):
                if let payloadString = barcode.payloadStringValue {
                    hasScanned = true
                    HapticManager.impact(style: .medium)
                    onBarcodeScanned(payloadString)
                }
            default:
                break
            }
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // Not needed for this implementation
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            onError(error)
        }
    }
}

// Scanner wrapper with overlay UI
struct BarcodeScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var appState: AppState
    let onBarcodeScanned: (String) -> Void
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            BarcodeScannerView(
                onBarcodeScanned: { barcode in
                    dismiss()
                    onBarcodeScanned(barcode)
                },
                onError: { error in
                    errorMessage = error.localizedDescription
                    showError = true
                }
            )
            .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                // Top bar with cancel button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Instructions
                VStack(spacing: 12) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 50)) // Large decorative icon
                        .foregroundStyle(.white)
                    
                    Text("Scan Product Barcode")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    Text("Position barcode within frame")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()
            }
        }
        .withSage(context: "User is scanning product barcode to identify food.", appState: appState)
        .alert("Scanner Error", isPresented: $showError) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(errorMessage)
        }
    }
}

// Availability check

