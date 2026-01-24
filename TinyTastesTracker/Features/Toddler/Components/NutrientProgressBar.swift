//
//  NutrientProgressBar.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import SwiftUI

struct NutrientProgressBar: View {
    let nutrient: Nutrient
    let count: Int
    let target: Int
    let onAskSage: () -> Void
    
    var progress: Double {
        min(Double(count) / Double(target), 1.0)
    }
    
    var isTargetMet: Bool {
        count >= target
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(nutrient.rawValue)
                    .font(.headline)
                    .foregroundStyle(nutrient.color)
                
                Spacer()
                
                Text("\(count)/\(target)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fontWeight(.bold)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 12)
                    
                    Capsule()
                        .fill(nutrient.color)
                        .frame(width: geometry.size.width * progress, height: 12)
                        .animation(.spring(duration: 0.6), value: progress)
                }
            }
            .frame(height: 12)
            
            if !isTargetMet {
                Button(action: onAskSage) {
                    HStack(spacing: 4) {
                        Text("Ask Sage for Ideas")
                        SageIcon(size: .small, style: .monochrome(nutrient.color))
                    }
                    .font(.caption)
                    .foregroundStyle(nutrient.color)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    VStack {
        NutrientProgressBar(nutrient: .iron, count: 2, target: 5, onAskSage: {})
        NutrientProgressBar(nutrient: .vitaminC, count: 7, target: 7, onAskSage: {})
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
