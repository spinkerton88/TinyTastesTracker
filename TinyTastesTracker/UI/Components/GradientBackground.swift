//
//  GradientBackground.swift
//  TinyTastesTracker
//
//  Re-usable background component for consistent theming across tabs
//

import SwiftUI

struct GradientBackground: View {
    let color: Color
    
    var body: some View {
        LinearGradient(
            colors: [color.opacity(0.15), color.opacity(0.05), Color.clear],
            startPoint: .top,
            endPoint: .center
        )
        .ignoresSafeArea()
    }
}

#Preview {
    ZStack {
        GradientBackground(color: .pink)
        Text("Newborn Mode")
    }
}
