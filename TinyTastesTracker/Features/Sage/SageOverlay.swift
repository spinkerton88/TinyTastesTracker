//
//  SageOverlay.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import SwiftUI

struct SageOverlayModifier: ViewModifier {
    var context: String
    @Bindable var appState: AppState
    
    @State private var showSageView = false
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showSageView = true
                } label: {
                    Image("sage.leaf.sprig")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            LinearGradient(
                                colors: [appState.themeColor, appState.themeColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: appState.themeColor.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 16)
            }
            .sheet(isPresented: $showSageView) {
                SageView(appState: appState)
            }
    }
}

extension View {
    func withSage(context: String, appState: AppState) -> some View {
        modifier(SageOverlayModifier(context: context, appState: appState))
    }
}
