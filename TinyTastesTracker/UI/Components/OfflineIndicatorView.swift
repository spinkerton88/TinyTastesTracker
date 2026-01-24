//
//  OfflineIndicatorView.swift
//  TinyTastesTracker
//
//  Reusable offline banner component
//

import SwiftUI

struct OfflineIndicatorView: View {
    @State private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                Text("Offline - Showing cached data")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.orange.gradient)
            )
            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

#Preview {
    VStack {
        OfflineIndicatorView()
        Spacer()
    }
    .padding()
}
