//

//  SettingsCell.swift
//  udpsnap
//
//  Created by Matěj Sychra on 26/06/2018.
//  Copyright © 2018 THiNX. All rights reserved.
//

import Foundation
import UIKit

class SettingsCellJitter: UITableViewCell {
    
    public var keyName: String? // name of the configuration key this cell stores to...
    public var unit: String = ""
    
    @IBOutlet weak var slider: UISlider?
    @IBOutlet weak var footerLabel: UILabel?
    @IBOutlet weak var valueLabel: UILabel?
 
    @IBAction public func valueChanged(sender: UISlider) {
        let value = sender.value
        self.valueLabel?.text = String(format: "%.2f \(unit)", value)
        if let key = keyName {
            UserDefaults.standard.set(sender.value, forKey: key)
            UserDefaults.standard.synchronize()
        }
    }
}
