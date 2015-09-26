//
//  AppDelegate.swift
//  iNotes
//
//  Created by Ramesh Lingappa on 9/26/15.
//  Copyright © 2015 Ramesh. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        initDropbox()
        
        return true
    }
    
    func initDropbox(){
        
        let dbSession = DBSession(appKey: Constants.DropBox.AppKey, appSecret: Constants.DropBox.AppSecret, root: kDBRootAppFolder)
        DBSession.setSharedSession(dbSession)
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        
        // sync changes if any pending exists
        DBSyncService.sharedInstance.checkAndSyncPending()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //MARK: Url handling
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {

        if DBSession.sharedSession().handleOpenURL(url) {
            
            // publish as notification
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.DropBox.DBLinkAcctNotification, object: DBSession.sharedSession().isLinked())
            
        }
        
        return false;
    }
    
}

