//
//  AppSpacing.swift
//  TinyTastesTracker
//
//  Centralized spacing design tokens
//

import SwiftUI

enum AppSpacing {
    // MARK: - Padding Values
    static let xs: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48

    // MARK: - Corner Radius
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusXL: CGFloat = 20

    // MARK: - Icon Sizes
    static let iconSmall: CGFloat = 16
    static let iconMedium: CGFloat = 24
    static let iconLarge: CGFloat = 32
    static let iconXL: CGFloat = 48

    // MARK: - Minimum Touch Target
    /// Minimum touch target size per Apple Human Interface Guidelines
    static let minTouchTarget: CGFloat = 44

    // MARK: - Card Dimensions
    static let cardMinHeight: CGFloat = 60
    static let cardMediumHeight: CGFloat = 100
    static let cardLargeHeight: CGFloat = 150

    // MARK: - Layout Spacing
    static let sectionSpacing: CGFloat = 24
    static let groupSpacing: CGFloat = 16
    static let listItemSpacing: CGFloat = 12

    // MARK: - Border Width
    static let borderThin: CGFloat = 1
    static let borderMedium: CGFloat = 2
    static let borderThick: CGFloat = 3

    // MARK: - Shadow
    static let shadowRadius: CGFloat = 8
    static let shadowOffset = CGSize(width: 0, height: 2)

    // MARK: - Helper Methods

    /// Standard card padding (horizontal + vertical)
    static var cardPadding: EdgeInsets {
        EdgeInsets(top: medium, leading: large, bottom: medium, trailing: large)
    }

    /// Standard section padding
    static var sectionPadding: EdgeInsets {
        EdgeInsets(top: sectionSpacing, leading: 0, bottom: sectionSpacing, trailing: 0)
    }
}
