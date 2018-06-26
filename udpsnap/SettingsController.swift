//
//  SettingsController.swift
//  udpsnap
//
//  Created by Matěj Sychra on 26/06/2018.
//  Copyright © 2018 THiNX. All rights reserved.
//

import Foundation
import UIKit

class SettingsController: UITableViewController {
    
    @IBAction func dismiss() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    var cells: [UITableViewCell] = []
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
            
        case 0:
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: "intervalSettingsCell", for: indexPath) as? SettingsCellInterval {
                cell.keyName = "com.thinx.interval"
                cell.unit = "s"
                return cell
            } else {
                assertionFailure()
            }
            
        case 1:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "jitterSettingsCell", for: indexPath) as? SettingsCellJitter {
                cell.keyName = "com.thinx.jitter"
                cell.unit = "ms"
                return cell
            } else {
                assertionFailure()
            }
            
        default:
            assertionFailure()
        }
        
        return tableView.dequeueReusableCell(withIdentifier: "intervalSettingsCell")!
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            
        case 0:
            return "Capture Interval"
            
        case 1:
            return "Jitter"
            
        case 2:
            return "Storage"
            
        default:
            return "Undefined"
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    }
    
}
