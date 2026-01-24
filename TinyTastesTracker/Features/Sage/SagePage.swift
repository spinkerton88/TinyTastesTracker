//
//  SagePage.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import SwiftUI

struct SagePage: View {
    @Bindable var appState: AppState
    
    var body: some View {
        SageChatView(appState: appState, initialContext: "User is in the main chat tab.")
    }
}
