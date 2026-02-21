import SwiftUI
import LinkPresentation

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

class LinkMetadataProvider: NSObject, UIActivityItemSource {
    let url: URL
    let title: String
    let subtitle: String?
    let fallbackText: String
    
    init(url: URL, title: String, subtitle: String? = nil, fallbackText: String) {
        self.url = url
        self.title = title
        self.subtitle = subtitle
        self.fallbackText = fallbackText
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return url
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        // If copying to clipboard or not sharing a link, provide the fallback text.
        if activityType == .copyToPasteboard || activityType == .mail {
            return fallbackText
        }
        // Return URL for iMessage to pull rich metadata
        return url
    }
    
    // Provide the rich link metadata
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.originalURL = url
        metadata.url = url
        metadata.title = title
        
        // Load the app icon as the image preview
        if let iconImage = UIImage(named: "AppIcon") {
            metadata.imageProvider = NSItemProvider(object: iconImage)
        } else if let assetImage = UIImage(named: "AppIcon") {
            // Fallback to searching assets explicitly if needed, but named "AppIcon" usually works if exposed. 
            // In most apps, getting the icon requires a specific asset name if standard bundle icon fetching isn't configured for UIImage.
            metadata.imageProvider = NSItemProvider(object: assetImage)
        }
        
        return metadata
    }
}
