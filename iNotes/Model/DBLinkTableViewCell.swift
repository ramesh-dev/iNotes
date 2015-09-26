//
//  DBLinkTableViewCell.swift
//  iNotes
//
//  Created by Ramesh Lingappa on 9/26/15.
//  Copyright © 2015 Ramesh. All rights reserved.
//

import UIKit

protocol DBLinkTableViewCellDelegate : class {
    
    func dbLinkTableViewCellLinkAction()
    
    func dbLinkTableViewCellUnLinkAction()

}

class DBLinkTableViewCell: UITableViewCell {
    
    @IBOutlet weak var linkButton : UIButton!
    @IBOutlet weak var unlinkButton : UIButton!
    
    weak var delegate : DBLinkTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    //IBAction 
    @IBAction func linkBtnAct(sender: AnyObject) {
        delegate?.dbLinkTableViewCellLinkAction()
    }
    
    @IBAction func unlinkBtnAct(sender: AnyObject) {
        delegate?.dbLinkTableViewCellUnLinkAction()
    }

    func setActiveAcctEmail(email : String){
        
        self.toggleView(email, hasActiveAcct: true)
    }
    
    func showNoAcctView(){
        
        self.toggleView("Link with Dropbox Account", hasActiveAcct: false)
    }
    
    private func toggleView(title : String, hasActiveAcct hasAcct : Bool){
        
        self.linkButton.setTitle(title, forState: UIControlState.Normal)
        
        self.linkButton.userInteractionEnabled = !hasAcct
        
        self.unlinkButton.hidden = !hasAcct
    }
    
}
