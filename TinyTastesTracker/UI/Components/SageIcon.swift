//
//  SageIcon.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/21/26.
//

import SwiftUI

struct SageIcon: View {
    enum Size {
        case small    // 16pt - Inline text
        case medium   // 24pt - Buttons, lists
        case large    // 48pt - Headers
        case custom(CGFloat)
        
        var pointSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 24
            case .large: return 48
            case .custom(let size): return size
            }
        }
    }
    
    enum Style {
        case standard // Original colors
        case monochrome(Color) // Single color
        case gradient // Purple-pink gradient
        case themedGradient(Color) // Gradient based on theme color
    }
    
    let size: Size
    let style: Style
    
    init(size: Size = .medium, style: Style = .standard) {
        self.size = size
        self.style = style
    }
    
    var body: some View {
        Group {
            switch style {
            case .standard:
                Image("sage.leaf.sprig")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .monochrome(let color):
                Image("sage.leaf.sprig")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(color)
            case .gradient:
                Image("sage.leaf.sprig")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            case .themedGradient(let color):
                Image("sage.leaf.sprig")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .frame(width: size.pointSize, height: size.pointSize)
    }
}

#Preview {
    HStack(spacing: 20) {
        SageIcon(size: .small, style: .monochrome(.green))
        SageIcon(size: .medium)
        SageIcon(size: .large, style: .gradient)
    }
}
