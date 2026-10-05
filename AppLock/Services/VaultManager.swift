import Foundation
import UIKit
import Photos
import AVFoundation

public final class VaultManager {
    public static let shared = VaultManager()
    
    private let fileManager = FileManager.default
    
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
        let fileURL = photosURL.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    // Load Intruder image
    public func loadIntruderPhoto(fileName: String) -> UIImage? {
        let fileURL = intrudersURL.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    // Generate video thumbnail
    public func generateVideoThumbnail(fileName: String) -> UIImage? {
        let videoURL = videosURL.appendingPathComponent(fileName)
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 0.5, preferredTimescale: 60)
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
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
