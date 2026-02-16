//
//  AppTypography.swift
//  TinyTastesTracker
//
//  Centralized typography design tokens
//

import SwiftUI

enum AppTypography {
    // MARK: - Font Sizes

    /// Extra small text (10pt) - captions, footnotes
    static let fontSizeXS: CGFloat = 10

    /// Small text (12pt) - secondary labels, metadata
    static let fontSizeSmall: CGFloat = 12

    /// Body text (16pt) - primary content
    static let fontSizeBody: CGFloat = 16

    /// Subheadline (14pt) - supporting text
    static let fontSizeSubheadline: CGFloat = 14

    /// Headline (18pt) - section titles
    static let fontSizeHeadline: CGFloat = 18

    /// Title (20pt) - card titles
    static let fontSizeTitle: CGFloat = 20

    /// Large title (28pt) - page headers
    static let fontSizeLargeTitle: CGFloat = 28

    /// Extra large title (34pt) - hero text
    static let fontSizeXL: CGFloat = 34

    // MARK: - Font Weights

    static let fontWeightLight: Font.Weight = .light
    static let fontWeightRegular: Font.Weight = .regular
    static let fontWeightMedium: Font.Weight = .medium
    static let fontWeightSemibold: Font.Weight = .semibold
    static let fontWeightBold: Font.Weight = .bold

    // MARK: - Predefined Styles

    /// Large title - bold, 28pt
    static var largeTitle: Font {
        .system(size: fontSizeLargeTitle, weight: fontWeightBold)
    }

    /// Title - semibold, 20pt
    static var title: Font {
        .system(size: fontSizeTitle, weight: fontWeightSemibold)
    }

    /// Headline - semibold, 18pt
    static var headline: Font {
        .system(size: fontSizeHeadline, weight: fontWeightSemibold)
    }

    /// Subheadline - medium, 14pt
    static var subheadline: Font {
        .system(size: fontSizeSubheadline, weight: fontWeightMedium)
    }

    /// Body - regular, 16pt
    static var body: Font {
        .system(size: fontSizeBody, weight: fontWeightRegular)
    }

    /// Body bold - bold, 16pt
    static var bodyBold: Font {
        .system(size: fontSizeBody, weight: fontWeightBold)
    }

    /// Caption - regular, 12pt
    static var caption: Font {
        .system(size: fontSizeSmall, weight: fontWeightRegular)
    }

    /// Caption bold - semibold, 12pt
    static var captionBold: Font {
        .system(size: fontSizeSmall, weight: fontWeightSemibold)
    }

    /// Footnote - regular, 10pt
    static var footnote: Font {
        .system(size: fontSizeXS, weight: fontWeightRegular)
    }

    // MARK: - Line Spacing

    static let lineSpacingTight: CGFloat = 4
    static let lineSpacingRegular: CGFloat = 6
    static let lineSpacingRelaxed: CGFloat = 8

    // MARK: - Letter Spacing

    static let letterSpacingTight: CGFloat = -0.5
    static let letterSpacingRegular: CGFloat = 0
    static let letterSpacingLoose: CGFloat = 0.5

    // MARK: - Helper Methods

    /// Apply standard body text style
    static func bodyText(_ text: String) -> Text {
        Text(text)
            .font(body)
            .foregroundColor(AppColors.primaryText)
    }

    /// Apply headline text style with theme color
    static func headlineText(_ text: String, mode: AppMode) -> Text {
        Text(text)
            .font(headline)
            .foregroundColor(AppColors.themeColor(for: mode))
    }

    /// Apply caption text style with secondary color
    static func captionText(_ text: String) -> Text {
        Text(text)
            .font(caption)
            .foregroundColor(AppColors.secondaryText)
    }
}
