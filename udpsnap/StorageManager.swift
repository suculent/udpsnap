//
//  StorageManager.swift
//  udpsnap
//
//  Created by Matěj Sychra on 26/06/2018.
//  Copyright © 2018 THiNX. All rights reserved.
//

import Foundation
import CloudKit
import UIKit

class StorageManager {
    
    //var accountStatus: CKAccountStatus
    
    var iCloudAvailable:Bool = false
    weak var controller: UIViewController?
    
    let fm = FileManager()
    
    init (viewController: UIViewController) {
        self.controller = viewController
        
        // TODO: Verify only when iCloud is enabled in Settings, also verify after configuration change
        verifySignIn()
    }
    
    func verifyCloudToken() {
        if let token = fm.ubiquityIdentityToken {
            print("iCloud token: \(token)")
            let data = NSKeyedArchiver.archivedData(withRootObject: token)
            UserDefaults.standard.set(data, forKey: "com.thinx.udpsnap.UbiquityIdentityToken")
            self.iCloudAvailable = true
        } else {
            UserDefaults.standard.removeObject(forKey: "com.thinx.udpsnap.UbiquityIdentityToken")
            self.iCloudAvailable = true
        }
        UserDefaults.standard.synchronize()
    }
    
    func verifySignIn() {
        
        CKContainer.default().accountStatus { (accountStatus: CKAccountStatus, error: Error?) in
            
            if accountStatus == CKAccountStatus.noAccount {
                
                let alert = UIAlertController(title: "Sign in to iCloud",
                                              message: "Sign in to your iCloud account to write records. On the Home screen, launch Settings, tap iCloud, and enter your Apple ID. Turn iCloud Drive on. If you don't have an iCloud account, tap Create a new Apple ID.",
                                              preferredStyle: UIAlertControllerStyle.alert)
                
                alert.addAction(UIAlertAction(title: "OK",
                                              style: UIAlertActionStyle.cancel,
                                              handler: { (action:UIAlertAction) in
                                                        // alert action handler
                                              }))
                
                self.controller?.present(alert, animated: true, completion: nil)
                
                self.iCloudAvailable = false
                
            } else {
                
                self.verifyCloudToken()
                
            }
            
        }
        
    }
    
    public func evictItem() {
        
    }
        
}

