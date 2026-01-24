//
//  TrackingTab.swift
//  TinyTastesTracker
//
//  Unified tracking tab for Explorer and Toddler modes
//

import SwiftUI
import SwiftData

struct TrackingTab: View {
    let mode: AppMode
    @Bindable var appState: AppState
    
    var body: some View {
        TrackingDashboardView(mode: mode, appState: appState)
    }
}
