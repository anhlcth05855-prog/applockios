import Foundation
import UIKit
import Photos
import AVFoundation

public final class VaultManager {
    public static let shared = VaultManager()
    
    private let fileManager = FileManager.default
    private let memoryCache = NSCache<NSString, UIImage>()
    
    private var vaultRootURL: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Vault", isDirectory: true)
    }
    
    public var photosURL: URL {
        vaultRootURL.appendingPathComponent("Photos", isDirectory: true)
    }
    
    public var videosURL: URL {
        vaultRootURL.appendingPathComponent("Videos", isDirectory: true)
    }
    
    public var intrudersURL: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Intruders", isDirectory: true)
    }
    
    private init() {
        createDirectoriesIfNeeded()
    }
    
    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: photosURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: videosURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: intrudersURL, withIntermediateDirectories: true)
    }
    
    // Save image to vault
    public func savePhoto(data: Data, originalName: String = "photo.jpg") throws -> VaultItem {
        let ext = (originalName as NSString).pathExtension.isEmpty ? "jpg" : (originalName as NSString).pathExtension
        let fileName = "vault_\(UUID().uuidString).\(ext)"
        let targetURL = photosURL.appendingPathComponent(fileName)
        
        try data.write(to: targetURL)
        
        return VaultItem(
            fileName: fileName,
            originalName: originalName,
            fileType: .photo,
            dateAdded: Date(),
            fileSize: Int64(data.count)
        )
    }
    
    // Save video to vault
    public func saveVideo(from sourceURL: URL, originalName: String = "video.mp4") throws -> VaultItem {
        let ext = sourceURL.pathExtension.isEmpty ? "mp4" : sourceURL.pathExtension
        let fileName = "vault_\(UUID().uuidString).\(ext)"
        let targetURL = videosURL.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: targetURL.path) {
            try fileManager.removeItem(at: targetURL)
        }
        
        try fileManager.copyItem(at: sourceURL, to: targetURL)
        
        let attributes = try fileManager.attributesOfItem(atPath: targetURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        // Calculate duration
        let asset = AVURLAsset(url: targetURL)
        let duration = CMTimeGetSeconds(asset.duration)
        
        return VaultItem(
            fileName: fileName,
            originalName: originalName,
            fileType: .video,
            dateAdded: Date(),
            fileSize: fileSize,
            duration: duration.isNaN ? 0 : duration
        )
    }
    
    // Load UIImage from Vault
    public func loadPhoto(fileName: String) -> UIImage? {
        if let cached = memoryCache.object(forKey: fileName as NSString) {
            return cached
        }
        let fileURL = photosURL.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) else { return nil }
        memoryCache.setObject(image, forKey: fileName as NSString)
        return image
    }
    
    // Load Intruder image
    public func loadIntruderPhoto(fileName: String) -> UIImage? {
        let cacheKey = "intruder_\(fileName)"
        if let cached = memoryCache.object(forKey: cacheKey as NSString) {
            return cached
        }
        let fileURL = intrudersURL.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) else { return nil }
        memoryCache.setObject(image, forKey: cacheKey as NSString)
        return image
    }
    
    // Generate video thumbnail (with caching)
    public func generateVideoThumbnail(fileName: String) -> UIImage? {
        let cacheKey = "vid_thumb_\(fileName)"
        if let cached = memoryCache.object(forKey: cacheKey as NSString) {
            return cached
        }
        let videoURL = videosURL.appendingPathComponent(fileName)
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 320, height: 320)
        
        let time = CMTime(seconds: 0.5, preferredTimescale: 60)
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let thumb = UIImage(cgImage: cgImage)
            memoryCache.setObject(thumb, forKey: cacheKey as NSString)
            return thumb
        } catch {
            return nil
        }
    }
    
    // Async high-performance loaders
    public func loadPhotoThumbnailAsync(fileName: String) async -> UIImage? {
        if let cached = memoryCache.object(forKey: fileName as NSString) {
            return cached
        }
        return await Task.detached(priority: .userInitiated) { [weak self] () -> UIImage? in
            guard let self = self else { return nil }
            let fileURL = self.photosURL.appendingPathComponent(fileName)
            guard let data = try? Data(contentsOf: fileURL),
                  let image = UIImage(data: data) else { return nil }
            let thumb = image.preparingThumbnail(of: CGSize(width: 240, height: 240)) ?? image
            self.memoryCache.setObject(thumb, forKey: fileName as NSString)
            return thumb
        }.value
    }
    
    public func loadVideoThumbnailAsync(fileName: String) async -> UIImage? {
        let cacheKey = "vid_thumb_\(fileName)"
        if let cached = memoryCache.object(forKey: cacheKey as NSString) {
            return cached
        }
        return await Task.detached(priority: .userInitiated) { [weak self] () -> UIImage? in
            guard let self = self else { return nil }
            let videoURL = self.videosURL.appendingPathComponent(fileName)
            let asset = AVAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: 320, height: 320)
            let time = CMTime(seconds: 0.5, preferredTimescale: 60)
            guard let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: nil) else { return nil }
            let thumb = UIImage(cgImage: cgImage)
            self.memoryCache.setObject(thumb, forKey: cacheKey as NSString)
            return thumb
        }.value
    }
    
    public func loadIntruderPhotoAsync(fileName: String) async -> UIImage? {
        let cacheKey = "intruder_\(fileName)"
        if let cached = memoryCache.object(forKey: cacheKey as NSString) {
            return cached
        }
        return await Task.detached(priority: .userInitiated) { [weak self] () -> UIImage? in
            guard let self = self else { return nil }
            let fileURL = self.intrudersURL.appendingPathComponent(fileName)
            guard let data = try? Data(contentsOf: fileURL),
                  let image = UIImage(data: data) else { return nil }
            let thumb = image.preparingThumbnail(of: CGSize(width: 160, height: 160)) ?? image
            self.memoryCache.setObject(thumb, forKey: cacheKey as NSString)
            return thumb
        }.value
    }
    
    // Delete item from disk
    public func deleteVaultFile(fileName: String, type: VaultMediaType) {
        let base = type == .photo ? photosURL : videosURL
        let target = base.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: target)
    }
    
    // Delete intruder photo
    public func deleteIntruderFile(fileName: String) {
        let target = intrudersURL.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: target)
    }
    
    // Export photo back to user Photos library
    public func exportPhotoToLibrary(fileName: String) async -> Bool {
        guard let image = loadPhoto(fileName: fileName) else { return false }
        
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    continuation.resume(returning: false)
                    return
                }
                
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    continuation.resume(returning: success && error == nil)
                }
            }
        }
    }
    
    // Export video back to user Photos library
    public func exportVideoToLibrary(fileName: String) async -> Bool {
        let videoURL = videosURL.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: videoURL.path) else { return false }
        
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    continuation.resume(returning: false)
                    return
                }
                
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                }) { success, error in
                    continuation.resume(returning: success && error == nil)
                }
            }
        }
    }
}
