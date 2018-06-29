//
//  CaptureViewController.swift
//  udpsnap
//
//  Created by Matěj Sychra on 24/06/2018.
//  Copyright © 2018 THiNX. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

@objc class CaptureViewController: SharedCaptureController, AVCapturePhotoCaptureDelegate {
    
    var sessionQueue: DispatchQueue?
    
    let deviceDiscoverySession = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
    
    private var captureIndex: Int = 0;
    
    // Image Data Channel Manager
    //let stillImageOutput = AVCaptureStillImageOutput()
    static var captureBuffer: Data?    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    // MARK: - Camera
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func saveCurrentOutputWithScreenshot(index: Int) {
        captureIndex = index        
        self.capturePhoto()
    }
    
    internal func saveImageDataWithCurrentIndex(_ imageData: Data!) {
        let filename = "step_\(self.captureIndex).jpeg" // OK
        let doc = self.URLForDocuments().appendingPathComponent(filename)
        self.saveDataWithFilename(path: doc, data: imageData)
        let cloud = self.URLForCloud().appendingPathComponent(filename)
        self.saveDataWithFilename(path: cloud, data: imageData)
    }
    
    func saveDataWithFilename(path: URL, data: Data) {
        do {
            try data.write(to: path)
        } catch let error {
            print(error)
        }
    }

    func URLForDocuments() -> URL! {
        var documentURL: URL?
        do {
            print("Saving to documents...");
            try documentURL = FileManager.default.url(
                for: FileManager.SearchPathDirectory.documentDirectory,
                in: FileManager.SearchPathDomainMask.userDomainMask,
                appropriateFor: nil, create: true)
        } catch {
            documentURL = nil
        }
        return documentURL
    }
    
        // You can write files and create subdirectories within the Documents subdirectory. You can create files or additional subdirectories in any directory you create.
    func URLForCloud() -> URL! {
        return FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents").absoluteURL
    }
    
    func setFocusOptions(device: AVCaptureDevice) {
        if device.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus) {
            do {
                try device.lockForConfiguration()
                device.focusMode = .autoFocus
            } catch let error as NSError {
                NSLog("\(error.localizedDescription)")
            }
            device.unlockForConfiguration()
        }
    }
    
    override func startCaptureWithCamera(_ position: AVCaptureDevice.Position) {
        
        guard !session.isRunning else { return }                        
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
            
        self.captureDevice = device
        self.setFocusOptions(device: self.captureDevice!)

        if let input = try? AVCaptureDeviceInput(device: device) {

            session.sessionPreset = AVCaptureSession.Preset.photo

            guard session.canAddInput(input) else { return }
            session.addInput(input)

            guard session.canAddOutput(output) else { return }
            session.addOutput(output)

            if #available(iOS 11.0, *) {
                output.setPreparedPhotoSettingsArray(
                    [AVCapturePhotoSettings(format:[AVVideoCodecKey:AVVideoCodecType.jpeg])],
                    completionHandler: nil
                )
            } else {
                output.setPreparedPhotoSettingsArray(
                    [AVCapturePhotoSettings(format:[AVVideoCodecKey:AVVideoCodecJPEG])],
                    completionHandler: nil)
            }

            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer!.frame = self.view.bounds
            previewLayer!.needsDisplayOnBoundsChange = true
            previewLayer!.accessibilityLabel = "camera_preview"
            previewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill

            // Replace preview layer
            for layer in self.view.layer.sublayers! {
                if layer.accessibilityLabel == "camera_preview" {
                    layer.removeFromSuperlayer()
                }
            }
            self.view.layer.insertSublayer(previewLayer!, at: 0)

            session.startRunning()

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(Progress.pause),
                name: NSNotification.Name.UIApplicationWillResignActive,
                object: nil
            )

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(Progress.resume),
                name: NSNotification.Name.UIApplicationWillEnterForeground,
                object: nil
            )
        }
    }
    
    @IBAction func didPressTakePhoto(_ sender: UIButton) {
        self.capturePhoto()
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [
            kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
            kCVPixelBufferWidthKey as String: 160,
            kCVPixelBufferHeightKey as String: 160
        ]
        settings.previewPhotoFormat = previewFormat
        
        if self.session.isRunning {
            self.output.capturePhoto(with: settings, delegate: self)
        } else {
            self.session.startRunning()
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            self.saveImageDataWithCurrentIndex(imageData)
        }
    }
    
    // This method you can use somewhere you need to know camera permission   state
    func askPermission() {
        
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            print("Already Authorized")
            DispatchQueue.main.async(){
                self.startCaptureWithCamera(AVCaptureDevice.Position.back)
            }
            break;
            
        case .denied:
            print("denied")
            
            let alert = UIAlertController(title: "Sorry :(" , message: "But  could you please grant permission for camera within device settings",  preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .cancel,  handler: nil)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
            break;
            
        case .restricted:
            print("restricted")
            break;
            
        default:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {
                [weak self]
                (granted :Bool) -> Void in
                
                DispatchQueue.main.async(){
                    if granted {
                        // User granted
                        print("User granted")
                        DispatchQueue.main.async(){
                            self!.startCaptureWithCamera(AVCaptureDevice.Position.back)
                        }
                    } else {
                        // User Rejected
                        print("User Rejected")
                        let alert = UIAlertController(title: "WHY?" , message:  "Camera it is the main feature of our application", preferredStyle: .alert)
                        let action = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
                        alert.addAction(action)
                        self?.present(alert, animated: true, completion: nil)
                    }
                }
            });
        }
    }
    
    @objc public override func pause() -> Void {
        super.pause()
    }
    
    @objc public override func resume() -> Void  {
        super.resume()
    }
}

