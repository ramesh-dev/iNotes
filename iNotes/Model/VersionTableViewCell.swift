//
//  VersionTableViewCell.swift
//  iNotes
//
//  Created by Ramesh Lingappa on 9/26/15.
//  Copyright © 2015 Ramesh. All rights reserved.
//

import UIKit

class VersionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var versionLabel : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        versionLabel.text = "\(NSBundle.applicationVersionNumber)(\(NSBundle.applicationBuildNumber))"
    }
}
