import Foundation
import AppKit
import CoreGraphics

guard CommandLine.arguments.count > 1 else {
    print("Usage: swift process_transparency.swift <input_directory>")
    exit(1)
}

let inputDirectory = CommandLine.arguments[1]
let fileManager = FileManager.default

// Configuration
// We can be more aggressive with the threshold because we are using flood fill.
// Any "whitish/greyish" pixel connected to the background will be removed.
// We protect internal white pixels (highlights) by connectivity.
let brightnessThreshold: CGFloat = 0.85 // Remove anything brighter than this (0-1)
let colorTolerance: CGFloat = 0.15     // Max saturation/deviation to be considered "grey/white"

struct Point: Hashable {
    let x: Int
    let y: Int
}

func processImage(at url: URL) {
    print("\nProcessing: \(url.lastPathComponent)")
    guard let image = NSImage(contentsOf: url),
          let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        print("Could not load image: \(url.lastPathComponent)")
        return
    }

    let width = cgImage.width
    let height = cgImage.height
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    let bitsPerComponent = 8
    
    // Create context for pixel manipulation
    guard let context = CGContext(data: nil,
                                width: width,
                                height: height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        print("Failed to create context")
        return
    }
    
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    
    guard let pixelData = context.data else { return }
    let dataBuffer = pixelData.bindMemory(to: UInt8.self, capacity: width * height * 4)
    
    // Dynamic Flood Fill based on Corner Color
    // We sample the corners to determine the "background color" dynamically.
    // Then we flood fill removing anything close to that color.
    
    let tolerance: CGFloat = 0.1 // 10% variation allowed for "solid" background + noise
    
    // Helper to calculate color distance
    func distance(from r1: CGFloat, g1: CGFloat, b1: CGFloat, to r2: CGFloat, g2: CGFloat, b2: CGFloat) -> CGFloat {
        let dr = r1 - r2
        let dg = g1 - g2
        let db = b1 - b2
        return sqrt(dr*dr + dg*dg + db*db)
    }
    
    var visited = Set<Point>()
    var queue = [Point]()
    var removedCount = 0
    
    // Seeds: Corners
    let seeds = [
        Point(x: 0, y: 0),
        Point(x: width-1, y: 0),
        Point(x: 0, y: height-1),
        Point(x: width-1, y: height-1)
    ]
    
    for seed in seeds {
        // Get Seed Color
        let offset = (seed.y * bytesPerRow) + (seed.x * bytesPerPixel)
        let rSeed = CGFloat(dataBuffer[offset]) / 255.0
        let gSeed = CGFloat(dataBuffer[offset + 1]) / 255.0
        let bSeed = CGFloat(dataBuffer[offset + 2]) / 255.0
        let alphaSeed = dataBuffer[offset + 3]
        
        // If already transparent, add to queue to find neighbors
        if alphaSeed == 0 {
            queue.append(seed)
            visited.insert(seed)
            continue
        }
        
        // Otherwise, this IS the background color. Start filling.
        // We assume corners are background.
        queue.append(seed)
        visited.insert(seed)
        // Make it transparent immediately
        dataBuffer[offset + 3] = 0
        removedCount += 1
        
        // Use this specific seed color for the fill originating from this specific corner
        // (Actually, a global fill is tricky if lighting varies. Color-based BFS is better.)
        
        // Simplified Logic:
        // We run a BFS from this seed.
        // Neighbors are added ONLY if they match the SEED color within tolerance.
        
        var localQueue = [Point]()
        localQueue.append(seed)
        
        while !localQueue.isEmpty {
            let p = localQueue.removeFirst()
            let x = p.x
            let y = p.y
            
            // Check neighbors
            let neighbors = [
                Point(x: x+1, y: y),
                Point(x: x-1, y: y),
                Point(x: x, y: y+1),
                Point(x: x, y: y-1)
            ]
            
            for n in neighbors {
                if n.x >= 0 && n.x < width && n.y >= 0 && n.y < height {
                    if !visited.contains(n) {
                        
                        // Check color match
                        let nOffset = (n.y * bytesPerRow) + (n.x * bytesPerPixel)
                        let nR = CGFloat(dataBuffer[nOffset]) / 255.0
                        let nG = CGFloat(dataBuffer[nOffset + 1]) / 255.0
                        let nB = CGFloat(dataBuffer[nOffset + 2]) / 255.0
                        let nA = dataBuffer[nOffset + 3]
                        
                        if nA == 0 {
                            // Already transparent, just traverse
                            visited.insert(n)
                            localQueue.append(n)
                            continue
                        }
                        
                        let dist = distance(from: nR, g1: nG, b1: nB, to: rSeed, g2: gSeed, b2: bSeed)
                        
                        // If roughly same color as seed (corner), remove it
                        if dist < tolerance {
                            dataBuffer[nOffset + 3] = 0 // Remove
                            removedCount += 1
                            visited.insert(n)
                            localQueue.append(n)
                        } else {
                            // Hit an edge (color different), stop traversing this path
                            // Do not add to visited? Ensure we don't re-check?
                            // Visited means "processed".
                            // If we don't add to visited, we might check it again from another path but result is same.
                            // Optimization: Don't visit again.
                            visited.insert(n)
                        }
                    }
                }
            }
        }
    }
    
    if removedCount > 0 {
        if let newCgImage = context.makeImage() {
            let newImage = NSImage(cgImage: newCgImage, size: image.size)
            if let tiffData = newImage.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                do {
                    try pngData.write(to: url)
                    print("  > Removed \(removedCount) pixels")
                } catch {
                    print("  > Failed to save")
                }
            }
        }
    } else {
        print("  > No background pixels found to remove")
    }
}

// Main Loop
do {
    let fileURLs = try fileManager.contentsOfDirectory(at: URL(fileURLWithPath: inputDirectory), includingPropertiesForKeys: nil)
    
    var count = 0
    for url in fileURLs {
        // PROCESS EVERYTHING: Original, Dark, and new ones.
        if url.pathExtension.lowercased() == "png" {
             processImage(at: url)
             count += 1
        }
    }
    print("\nBatch processing complete. Processed \(count) images.")
} catch {
    print("Error reading directory: \(error)")
}
