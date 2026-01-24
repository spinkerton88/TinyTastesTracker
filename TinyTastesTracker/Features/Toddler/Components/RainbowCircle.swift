//
//  RainbowCircle.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import SwiftUI

struct RainbowCircle: View {
    let color: FoodColor
    let count: Int
    
    var isAchieved: Bool {
        count > 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(color.displayColor.opacity(0.3), lineWidth: 3)
                    .frame(width: 50, height: 50)
                
                // Filled circle if achieved
                if isAchieved {
                    Circle()
                        .fill(color.displayColor)
                        .frame(width: 42, height: 42)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Circle()
                        .fill(color.displayColor.opacity(0.1))
                        .frame(width: 42, height: 42)
                }
                
                // Count or Checkmark
                if isAchieved {
                    Text("\(count)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .shadow(radius: 1)
                }
            }
            
            Text(color.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .animation(.bouncy, value: count)
    }
}

#Preview {
    HStack {
        RainbowCircle(color: .red, count: 0)
        RainbowCircle(color: .green, count: 3)
        RainbowCircle(color: .purple, count: 1)
    }
}
