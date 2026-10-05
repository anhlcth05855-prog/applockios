import Foundation
import AVFoundation
import UIKit

public final class CameraManager: NSObject, AVCapturePhotoCaptureDelegate {
    public static let shared = CameraManager()
    
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var completionHandler: ((Result<String, Error>) -> Void)?
    
    private override init() {
        super.init()
    }
    
    public func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    public func captureIntruderPhoto(targetAppName: String, completion: @escaping (Result<String, Error>) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard status == .authorized else {
            completion(.failure(NSError(domain: "CameraManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Chưa cấp quyền Camera"])))
            return
        }
        
        self.completionHandler = completion
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.setupAndCapture()
        }
    }
    
    private func setupAndCapture() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            DispatchQueue.main.async {
                self.completionHandler?(.failure(NSError(domain: "CameraManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy camera trước"])))
            }
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            let output = AVCapturePhotoOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            self.photoOutput = output
            self.captureSession = session
            
            session.startRunning()
            
            // Wait brief moment for sensor exposure adjustment
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.25) {
                let settings = AVCapturePhotoSettings()
                settings.flashMode = .off
                output.capturePhoto(with: settings, delegate: self)
            }
        } catch {
            DispatchQueue.main.async {
                self.completionHandler?(.failure(error))
            }
        }
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        captureSession?.stopRunning()
        captureSession = nil
        photoOutput = nil
        
        if let error = error {
            DispatchQueue.main.async {
                self.completionHandler?(.failure(error))
            }
            return
        }
        
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            DispatchQueue.main.async {
                self.completionHandler?(.failure(NSError(domain: "CameraManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Lỗi xử lý hình ảnh"])))
            }
            return
        }
        
        // Save intruder image to sandbox
        do {
            let fileManager = FileManager.default
            let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let intruderFolder = documents.appendingPathComponent("Intruders", isDirectory: true)
            
            if !fileManager.fileExists(atPath: intruderFolder.path) {
                try fileManager.createDirectory(at: intruderFolder, withIntermediateDirectories: true)
            }
            
            let fileName = "intruder_\(UUID().uuidString).jpg"
            let fileURL = intruderFolder.appendingPathComponent(fileName)
            
            // Fix orientation
            let normalizedImage = image.fixedOrientation()
            if let jpegData = normalizedImage.jpegData(compressionQuality: 0.8) {
                try jpegData.write(to: fileURL)
                DispatchQueue.main.async {
                    self.completionHandler?(.success(fileName))
                }
            } else {
                throw NSError(domain: "CameraManager", code: 501, userInfo: [NSLocalizedDescriptionKey: "Không thể nén JPEG"])
            }
        } catch {
            DispatchQueue.main.async {
                self.completionHandler?(.failure(error))
            }
        }
    }
}

// UIImage orientation normalizer
extension UIImage {
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage ?? self
    }
}
