//
//  SharedCaptureController.swift
//  udpsnap
//
//  Created by Matěj Sychra on 24/06/2018.
//  Copyright © 2018 THiNX. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

/** Shared code for all capture view controllers should be placed here on refactoring */

let flashViewBackgroundColor = UIColor(red: 1, green: 0.95, blue: 0.95, alpha: 1)

class SharedCaptureController: UIViewController, UIPopoverPresentationControllerDelegate {    
    
    // MARK: Capture Session and Output
    
    let session = AVCaptureSession()
    let output = AVCapturePhotoOutput()
    var captureDevice: AVCaptureDevice?
    var selectedDevicePosition = AVCaptureDevice.Position.back // as required by design
    var previewLayerConnection: AVCaptureConnection?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    // Session Control Observers
    let CameraControlObservableSettingAdjustingFocus = "CameraControlObservableSettingAdjustingFocus"
    fileprivate var controlObservers = [String: [AnyObject]]()
    
    internal func pause() {
        self.session.stopRunning()
    }
    
    internal func resume() {
        self.session.startRunning()
    }
    
    internal func startCapture() {
        
        if session.isRunning {
            session.stopRunning()
            self.unobserveValues()
            for input in session.inputs {
                session.removeInput(input)
            }
            for output in session.outputs {
                session.removeOutput(output)
            }
        }
        self.observeValues()
        startCaptureWithCamera(selectedDevicePosition)
    }
    
    /** Overridden in a subclass */
    internal func startCaptureWithCamera(_ position: AVCaptureDevice.Position) {
        assertionFailure("startCaptureWithCamera must be overridden in a subclass.")
    }
    
    // MARK: Tap Gesture Recognizer for Focus & Audio
    
    var tapGestureRecognizer: UITapGestureRecognizer?
    
    /** Attaches tap gesture recognizer to force focus and play sound */
    internal func setupFocusGestureRecognizer() {
        if tapGestureRecognizer == nil {
            tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SharedCaptureController.tap(_:)))
            tapGestureRecognizer!.numberOfTapsRequired = 1
            tapGestureRecognizer!.numberOfTouchesRequired = 1
            
            if let view = self.view {
                view.addGestureRecognizer(tapGestureRecognizer!)
            } else {
                assertionFailure("No view for recognizer to attach.")
            }
        } else {
            assertionFailure("Tap recognizer already added.")
        }
    }
    
    @objc internal func tap(_ tapGestureRecognizer: UITapGestureRecognizer) {
        if tapGestureRecognizer.state == UIGestureRecognizerState.ended {
            let thisFocusPoint: CGPoint = tapGestureRecognizer.location(in: self.view)
            let focus_x = thisFocusPoint.x/self.view.frame.size.width
            let focus_y = thisFocusPoint.y/self.view.frame.size.height
            
            if let device = self.captureDevice {
                
                if device.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus) &&
                    device.isFocusPointOfInterestSupported {
                    
                    do {
                        try device.lockForConfiguration()
                        device.focusPointOfInterest = CGPoint(x: focus_x, y: focus_y)
                        device.focusMode = .autoFocus
                        //self.audioFX.play(SoundType.tap)
                    } catch let error as NSError {
                        NSLog("\(error.localizedDescription)")
                    }
                    
                    device.unlockForConfiguration()
                } else {
                    //Answers.logCustomEvent(withName: "ANALYTIC:focus-not-supported", customAttributes: nil)
                }
            }
        }
    }
    
    // MARK: - Camera Focus
    
    fileprivate var adjustingFocusContext = 0
    
    func observeValues() {
        captureDevice?.addObserver(self, forKeyPath: "adjustingFocus", options: .new, context: &adjustingFocusContext)
    }
    
    func unobserveValues() {
        captureDevice?.removeObserver(self, forKeyPath: "adjustingFocus", context: &adjustingFocusContext)
    }
    
    internal override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        _ = ""
        let _: AnyObject = change![NSKeyValueChangeKey.newKey]! as AnyObject
        
    }
    
    // MARK: Flash Effect
    
    func presentFlashEffect() -> Void {
        let flashView = UIView(frame: self.view.frame)
        flashView.backgroundColor = flashViewBackgroundColor
        flashView.tag = 999
        flashView.isOpaque = false
        
        self.view.addSubview(flashView)
        self.view.setNeedsDisplay()
        
        UIView.setAnimationCurve(UIViewAnimationCurve.easeOut)
        UIView.animate(withDuration: 2.0, animations: {
            flashView.alpha = 0
        }, completion: { (finished) -> Void in
            // completion
            if (finished) {
                self.view.viewWithTag(999)?.removeFromSuperview()
            }
        })
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if session.isRunning {
            print("Restarting session after rotation...")
            startCapture()
        }
    }
}
