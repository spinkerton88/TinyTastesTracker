import UIKit

extension UIImage {
    /// Removes the background using a Flood Fill algorithm starting from the corners.
    /// This is safer than replacing all white pixels because it protects white details *inside* the object.
    /// - Parameter tolerance: The tolerance for "white" (0-255). Default 50 handles shadows well.
    /// - Returns: A new image with transparent background.
    func removingSolidBackground(tolerance: Int = 50) -> UIImage? {
        guard let inputCGImage = self.cgImage else { return nil }
        
        // 1. Get pixel data
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let width = inputCGImage.width
        let height = inputCGImage.height
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        let bytesPerRow = bytesPerPixel * width
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        guard let context = CGContext(data: nil,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: bitsPerComponent,
                                    bytesPerRow: bytesPerRow,
                                    space: colorSpace,
                                    bitmapInfo: bitmapInfo) else {
            return nil
        }
        
        context.draw(inputCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let buffer = context.data else { return nil }
        let pixelBuffer = buffer.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
        
        // 2. Flood Fill Algorithm (DFS)
        // We start from corners and "eat" the white background inwards.
        // This protects internal white parts of the food that aren't connected to the background.
        
        let threshold = UInt8(max(0, 255 - tolerance))
        
        // Stack for DFS (x, y) coordinates
        var stack: [(Int, Int)] = []
        stack.reserveCapacity(width * height / 4) // Optimization
        
        // Start from corners
        stack.append((0, 0))
        stack.append((width - 1, 0))
        stack.append((0, height - 1))
        stack.append((width - 1, height - 1))
        
        // Keep track of visited pixels to avoid infinite loops
        var visited = [Bool](repeating: false, count: width * height)
        
        while !stack.isEmpty {
            let (x, y) = stack.removeLast()
            let index = y * width + x
            
            // Bounds check not needed due to logic below, but visited check is crucial
            if visited[index] { continue }
            visited[index] = true
            
            let offset = index * bytesPerPixel
            let r = Int(pixelBuffer[offset])
            let g = Int(pixelBuffer[offset + 1])
            let b = Int(pixelBuffer[offset + 2])
            
            // Check if pixel is "Background"
            // We now target Middle Gray (128, 128, 128) which is our new prompt standard.
            // This prevents "White Halos" in Dark Mode.
            
            // Logic: Pixel is background if it is neutral (R=G=B) and within gray range
            let isNeutral = abs(r - g) < 15 && abs(g - b) < 15 && abs(r - b) < 15
            
            // Check for Gray Range (roughly 100-180) OR bright white (230+)
            // We include white just in case the model generates white highlights or ignores the prompt
            let isGray = r > 90 && r < 190
            let isWhite = r > 230
            
            if isNeutral && (isGray || isWhite) {
                // It is background -> Make Transparent
                pixelBuffer[offset + 3] = 0 // Alpha = 0
                
                // Add neighbors to stack
                if x > 0 { stack.append((x - 1, y)) }
                if x < width - 1 { stack.append((x + 1, y)) }
                if y > 0 { stack.append((x, y - 1)) }
                if y < height - 1 { stack.append((x, y + 1)) }
            }
        }
        
        // 3. Create new image
        guard let outputCGImage = context.makeImage() else { return nil }
        return UIImage(cgImage: outputCGImage, scale: self.scale, orientation: self.imageOrientation)
    }
}
