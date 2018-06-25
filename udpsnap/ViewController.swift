//
//  ViewController.swift
//  udpsnap
//
//  Created by Matěj Sychra on 24/06/2018.
//  Copyright © 2018 THiNX. All rights reserved.
//

import UIKit

/** Displays capture view through superclasses. Manages saving on command. */
class ViewController: CaptureViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var statusLabel: UILabel!
    
    private var lastStep:Int = 0
    private var manager: UDPManager?    
    
    // MARK: Overrides
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override var preferredStatusBarUpdateAnimation : UIStatusBarAnimation {
        return UIStatusBarAnimation.fade
    }
    
    
    override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
    
    // No rotation, because it would negatively affect image quality, especially on low-res cameras
    override var shouldAutorotate : Bool {
        return false
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.manager = UDPManager(delegate: self)
        setupFocusGestureRecognizer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        askPermission()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = self.view.layer.bounds
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.session.isRunning {
            self.session.stopRunning()
        }
    }
    
    // MARK: Capture
    
    @objc public func snapNotification(not: Notification) {
        let message = not.userInfo!["message"] as! String
        let indexString = message.replacingOccurrences(of: "P:", with: "").replacingOccurrences(of: "\r\n", with: "")
        let index = Int(indexString)!
        capture(step: index)
    }
    
    func capture(step: Int) {
        saveCurrentOutputWithScreenshot(index: step) // inherited from super class
        lastStep = step;
    }
}

/** UDPManagerProtocol, capture is triggered from UDPServer through UDPServerDelegate. */

extension ViewController: UDPManagerProtocol {
    func captureWhenCompleted(step: Int) {
        lastStep = step;
        self.statusLabel.text = String(step)
        self.capture(step: step);
    }
}
