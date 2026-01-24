//
//  ToastView.swift
//  TinyTastesTracker
//
//  Created by Antigravity on 1/19/25.
//

import SwiftUI

struct ToastView: View {
    let message: String
    let buttonTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        HStack {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
            
            Spacer()
            
            if let buttonTitle, let action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Constants.explorerColor) // Or theme color
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 4)
        .padding(.horizontal)
    }
}
