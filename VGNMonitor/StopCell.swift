//
//  StopCell.swift
//  VGNMonitor
//
//  Created by Torsten Wauer on 07/05/16.
//  Copyright © 2016 twdorado. All rights reserved.
//

import UIKit

class StopCell: UITableViewCell {

    @IBOutlet weak var lineNumber: UITextField!
    @IBOutlet weak var stopName: UITextField!
    @IBOutlet weak var cityName: UITextField!
    @IBOutlet weak var departureTime: UITextField!
    @IBOutlet weak var departureDate: UITextField!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
