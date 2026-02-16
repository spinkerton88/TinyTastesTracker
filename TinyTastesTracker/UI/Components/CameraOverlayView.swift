//
//  CameraOverlayView.swift
//  TinyTastesTracker
//
//  Standardized overlay for camera views
//

import SwiftUI

struct CameraOverlayView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let subtitle: String?
    let iconName: String
    
    // Optional custom action for the close button, defaults to dismiss
    var onClose: (() -> Void)?
    
    var body: some View {
        VStack {
            // Top bar with close button
            HStack {
                Spacer()
                Button {
                    if let onClose = onClose {
                        onClose()
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4)
                }
                .padding()
            }
            
            Spacer()
            
            // Bottom Instruction Card
            VStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    ZStack {
        Color.black
        CameraOverlayView(
            title: "Scan Product Barcode",
            subtitle: "Position barcode within frame",
            iconName: "barcode.viewfinder"
        )
    }
}
