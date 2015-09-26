//
//  SettingsViewController.swift
//  iNotes
//
//  Created by Ramesh Lingappa on 9/26/15.
//  Copyright © 2015 Ramesh. All rights reserved.
//

import UIKit
import MBProgressHUD

class SettingsViewController: UITableViewController, DBLinkTableViewCellDelegate, DBRestClientDelegate {

    @IBOutlet weak var dbLinkTableViewCell: DBLinkTableViewCell!
    
    var alertHud : MBProgressHUD?
    
    lazy var dbRestClient = DBRestClient(session: DBSession.sharedSession())
    
    override func viewDidLoad() {
    
        super.viewDidLoad()
        
        alertHud =  MBProgressHUD(view: self.view)
        self.view.addSubview(alertHud!)
        
        dbLinkTableViewCell.delegate = self
        
        updateDropBoxLinkStatus()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dbDidLinkAcctNotification:", name:Constants.DropBox.DBLinkAcctNotification, object: nil)
    }
    
    func updateDropBoxLinkStatus (){
        
        if DBSession.sharedSession().isLinked() {
            
            if let acctInfo = DBSyncService.sharedInstance.getActiveAcctEmail() {
                dbLinkTableViewCell.setActiveAcctEmail(acctInfo.email)
            }else {
                
                // somehow info was deleted, trying to refetch
                dbLinkTableViewCell.setActiveAcctEmail("Unknown")
               
                dbRestClient.delegate = self
                dbRestClient.loadAccountInfo()
            }
            
            dbLinkTableViewCell.setActiveAcctEmail( DBSyncService.sharedInstance.getActiveAcctEmail()?.email ?? "Unknown")
            
            
        } else {
            dbLinkTableViewCell.showNoAcctView()
        }
    }
    
    
    //MARK: Link Account Section
    
    func dbDidLinkAcctNotification(notification : NSNotification){
        
        if DBSession.sharedSession().isLinked() {
            
            dbRestClient.delegate = self
            dbRestClient.loadAccountInfo()
        }else {
            self.alertHud?.showText("Unable to connect account", detailMsg: "Please try again", delay: 2)
        }
    }

    //MARK: DBLinkTableViewCell Delegates
    
    func dbLinkTableViewCellLinkAction() {
                
        alertHud?.showLoader("Linking...")
        DBSession.sharedSession().linkFromController(self)
    }
    
    func dbLinkTableViewCellUnLinkAction() {

        let alertView = UIAlertController(title: "Confirm Unlink", message: "Sure want to unlink this account? Files will no longer get synced to this account", preferredStyle: UIAlertControllerStyle.Alert)
        
        let okBtn = UIAlertAction(title: "Unlink", style: UIAlertActionStyle.Destructive, handler: {[unowned self] (alertAction) -> Void in
            
            self.alertHud?.showLoader("Unlinking Dropbox Account")
            
            if !DBSyncService.sharedInstance.unlinkActiveAcct() {
                self.alertHud?.showText("Unable to unlink you account currently", detailMsg: "please try again later", delay: 2)
                return
            }
            
            self.updateDropBoxLinkStatus()
            self.alertHud?.showText("Account unlinked successfully", delay: 2)

        })
        
        let cancelBtn = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler:nil)
        
        alertView.addAction(cancelBtn)
        alertView.addAction(okBtn)
        
        self.presentViewController(alertView, animated: true, completion: nil)
    }
    
    //MARK: DBRestClient Delegates 
    
    func restClient(client: DBRestClient!, loadedAccountInfo info: DBAccountInfo!) {
        
        if !DBSyncService.sharedInstance.saveActiveAcctInfo(DBAcctInfo(accountInfo: info)) {
            
            DBSession.sharedSession().unlinkAll()
            self.alertHud?.showText("Unable to connect account", detailMsg: "Please try again", delay: 2)
            return
        }
        
        self.alertHud?.hide(true)
        
        self.updateDropBoxLinkStatus()
    }
    
    func restClient(client: DBRestClient!, loadAccountInfoFailedWithError error: NSError!) {
        
        print("error : \(error)")
        DBSession.sharedSession().unlinkAll()
        self.alertHud?.showText("Unable to connect account", detailMsg: "Please try again", delay: 2)
    }
    
    
}
