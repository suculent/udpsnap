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
        
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var playStopButton: UIButton! // better than having stop and play as separate functions
    @IBOutlet weak var settingsButton: UIButton! // to configure settings like delay and jitter, make another project, list and export data...
    
    private var lastStep:Int = 0
    private var manager: UDPManager?
    private var storage: StorageManager?
    
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
        self.storage = StorageManager(viewController: self)
        
        setupFocusGestureRecognizer()
        NotificationCenter.default.addObserver(self, selector: #selector(deviceResolved), name: NSNotification.Name("Resolved"), object: nil)
        self.statusLabel.text = "Waiting..."
    }
    
    @objc func deviceResolved() {
        self.statusLabel.text = "Ready"
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
    
    // MARK: Commands
    
    var isRunning: Bool = false; // TODO: FIXME!       
    
    @IBAction func rewindPressed(_ sender: Any) {
        
        if isRunning {
            isRunning = false
            manager?.stop()
        }
        manager?.rewind()
    }
    
    lazy var allStates:UIControlState = [.normal, .highlighted, .selected]
    
    lazy var stopTitle = NSLocalizedString("Stop", comment: "Command button label")
    lazy var playTitle = NSLocalizedString("Play", comment: "Command button label")
    
    lazy var stopImage = UIImage(named: "stop")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
    lazy var playImage = UIImage(named: "play")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
    
    lazy var rewImage = UIImage(named: "rewind")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
    
    lazy var settingsImage = UIImage(named: "settings")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
    
    @IBAction func playStopPressed(_ sender: Any) {
        
        isRunning = !isRunning
        
        if isRunning {
            manager?.start()
            self.playStopButton.setImage(stopImage, for: allStates)
        } else {
            manager?.stop()
            self.playStopButton.setImage(playImage, for: allStates)
        }
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
