//

//  SettingsCell.swift
//  udpsnap
//
//  Created by Matěj Sychra on 26/06/2018.
//  Copyright © 2018 THiNX. All rights reserved.
//

import Foundation
import UIKit

class SettingsCellInterval: UITableViewCell {

    public var keyName: String? // name of the configuration key this cell stores to...
    public var unit: String = ""
    
    @IBOutlet weak var slider: UISlider?
    @IBOutlet weak var footerLabel: UILabel?
    @IBOutlet weak var valueLabel: UILabel?
 
    @IBAction public func valueChanged(sender: UISlider) {
        let value = floor(sender.value)
        sender.value = value
        self.valueLabel?.text = String(format: "%.1f \(unit)", value)
        if let key = keyName {
            UserDefaults.standard.set(sender.value, forKey: key)
            UserDefaults.standard.synchronize()
            UDPManager.sharedInstance.interval(millis: Int(floor(sender.value * 1000)))
        }
    }
}
