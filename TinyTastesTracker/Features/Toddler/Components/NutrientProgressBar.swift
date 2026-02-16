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
    let isExpanded: Bool
    let isLoading: Bool
    let suggestions: [NutrientFoodSuggestion]
    let onToggleExpand: () -> Void
    
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
                Button(action: onToggleExpand) {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Hide Ideas" : "Ask Sage for Ideas")
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        if !isExpanded {
                            SageIcon(size: .small, style: .monochrome(nutrient.color))
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(nutrient.color)
                }
                .padding(.top, 4)
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 4)
                                Text("Asking Sage...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                        } else if suggestions.isEmpty {
                            Text("Sage couldn't find any specific suggestions right now.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(suggestions, id: \.foodName) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(item.foodName)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Text(item.reasoning)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Text("💡 " + item.servingTip)
                                        .font(.caption2)
                                        .foregroundStyle(nutrient.color)
                                        .padding(6)
                                        .background(nutrient.color.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .padding(.vertical, 4)
                                
                                if item.foodName != suggestions.last?.foodName {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .animation(.spring(duration: 0.3), value: isExpanded)
    }
}

#Preview {
    VStack {
        NutrientProgressBar(
            nutrient: .iron,
            count: 2,
            target: 5,
            isExpanded: false,
            isLoading: false,
            suggestions: [],
            onToggleExpand: {}
        )
        NutrientProgressBar(
            nutrient: .vitaminC,
            count: 7,
            target: 7,
            isExpanded: true,
            isLoading: true,
            suggestions: [],
            onToggleExpand: {}
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
