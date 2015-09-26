//
//  DBSyncService.swift
//  iNotes
//
//  Created by Ramesh Lingappa on 9/26/15.
//  Copyright © 2015 Ramesh. All rights reserved.
//

import Foundation
import ReachabilitySwift

class DBSyncService : NSObject, DBRestClientDelegate {
    
    static let dbNotesFolderPath = "/notes"
    static let pendingSyncNotesKey = "pendingSyncNotes"
    static let dbActiveAcctInfoKey = "_dbActiveAcctInfo"
    
    static let syncMaxRetryCount : Int = 3
    
    static let sharedInstance = DBSyncService()
    
    private var dbRestClient : DBRestClient?
    
    // [ID : retryCount]
    private var pendingSync : [String : Int]?
    
    let networkChecker = Reachability.reachabilityForInternetConnection()
    
    private override init() {
        
        super.init()
        
        self.subscribeForNetworkChange()
    }
    
    private func subscribeForNetworkChange(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:", name: ReachabilityChangedNotification, object: networkChecker)
        networkChecker?.startNotifier()
    }
    
    func getDBRestClient() -> DBRestClient {
        
        if dbRestClient == nil {
            dbRestClient = DBRestClient(session: DBSession.sharedSession())
            dbRestClient!.delegate = self
        }
        return dbRestClient!
        
    }
    
    func getDbNotePath(fileName : String) -> String{
        return "\(DBSyncService.dbNotesFolderPath)/\(fileName)"
    }
    
    //MARK: Sync Services
    
    func getPendingSync() -> [String : Int]?{
        
        if pendingSync == nil {
            
            if let notes = NSUserDefaults.standardUserDefaults().objectForKey(DBSyncService.pendingSyncNotesKey) as? [String : Int] {
                pendingSync = notes
            }
        }
        
        return pendingSync
    }
    
    private func savePendingSync(syncs : [String : Int]){
        
        NSUserDefaults.standardUserDefaults().setObject(syncs, forKey: DBSyncService.pendingSyncNotesKey)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        pendingSync = syncs
    }
    
    func clearAllPendingSync(){
        
        NSUserDefaults.standardUserDefaults().removeObjectForKey(DBSyncService.pendingSyncNotesKey)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        pendingSync = nil
    }
    
    private func addToPendingSync(note : Note){
        
        var sync = getPendingSync() ?? [:]
        
        var retryCount = sync[note.id] ?? -1
        
        retryCount++
        
        sync[note.id] = retryCount
        
        savePendingSync(sync)
    }
    
    private func removeIdFromSync(id : String){
        
        if var sync = getPendingSync() {
            
            sync[id] = nil
            
            savePendingSync(sync)
        }
    }
    
    //MARK: Note Sync Func
    func syncNote(note : Note, deleted : Bool){
        
        if !DBSession.sharedSession().isLinked() {
            return
        }
        
        addToPendingSync(note)
        
        if let checker = networkChecker where checker.isReachable(){
            if deleted {
                
                dispatch_async(dispatch_get_main_queue(), {  [unowned self] () -> Void in
                    self.getDBRestClient().deletePath(self.getDbNotePath(note.localFileName))
                    })
                
            }else {
                
                dispatch_async(dispatch_get_main_queue(), { [unowned self] () -> Void in
                    // either create or update
                    let localFilePath = NoteService.sharedInstance.notesPath.stringByAppendingPathComponent(note.localFileName)
                    
                    self.getDBRestClient().uploadFile(note.localFileName, toPath: DBSyncService.dbNotesFolderPath, withParentRev: note.dbRev, fromPath: localFilePath)
                })
            }
        }
    }
    
    //MARK: DBRestClient Delegates
    
    func restClient(client: DBRestClient!, uploadedFile destPath: String!, from srcPath: String!, metadata: DBMetadata!) {
        
        let noteId = metadata.filename.stringByReplacingOccurrencesOfString(".txt", withString: "")
        
        removeIdFromSync(noteId)
        
        if let note = NoteService.sharedInstance.getNote(noteId) {
            
            note.dbRev = metadata.rev
            NoteService.sharedInstance.saveNoteMeta(note)
        }
    }
    
    // delete delegates
    func restClient(client: DBRestClient!, deletedPath path: String!) {
        
        // for now this is fine
        let noteId = path.stringByReplacingOccurrencesOfString(".txt", withString: "").stringByReplacingOccurrencesOfString(DBSyncService.dbNotesFolderPath+"/", withString: "")
        
        print("deleted Path : \(path) noteId : \(noteId)")
        
        removeIdFromSync(noteId)
    }
    
    func restClient(client: DBRestClient!, deletePathFailedWithError error: NSError!) {
        
        if error.code == 404 {
            if let path = error.userInfo["path"] as? String {
                self.restClient(client, deletedPath: path)
            }
        }
    }
    
    //MARK: Account Helpers
    
    func getActiveAcctEmail() -> DBAcctInfo? {
        
        if DBSession.sharedSession().isLinked() {
            
            if let data = NSUserDefaults.standardUserDefaults().objectForKey(DBSyncService.dbActiveAcctInfoKey) as? NSData {
                
                if let acct = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? DBAcctInfo {
                    return acct
                }
            }
        }
        
        return nil
    }
    
    func saveActiveAcctInfo(acctInfo  : DBAcctInfo) -> Bool {
        
        NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(acctInfo), forKey: DBSyncService.dbActiveAcctInfoKey)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        subscribeForNetworkChange()
        
        return true
    }
    
    func unlinkActiveAcct() -> Bool {
        
        DBSession.sharedSession().unlinkAll()
        
        NSUserDefaults.standardUserDefaults().removeObjectForKey(DBSyncService.dbActiveAcctInfoKey)
        
        NSUserDefaults.standardUserDefaults().synchronize()
        
        clearAllPendingSync()
        
        stopSyncChecker()
        
        return true
    }
    
    //MARK: Sync Check
    
    func checkAndSyncPending(){
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { [unowned self] () -> Void in
            
            if DBSession.sharedSession().isLinked(){
                
                if let checker = self.networkChecker where checker.isReachable(), let sync = self.getPendingSync() where sync.count > 0 {
                    
                    for (id, retry) in sync {
                        
                        if let note = NoteService.sharedInstance.getNote(id) {
                            
                            self.syncNote(note, deleted: false)
                            
                        }else {
                            // deleted
                        
                            self.syncNote(Note(id, title:""), deleted: true)
                        }
                        
                        if retry >= DBSyncService.syncMaxRetryCount{
                            self.removeIdFromSync(id)
                        }
                    }
                }
            }
            })
    }
    
    func stopSyncChecker(){
        
        networkChecker?.stopNotifier()
        NSNotificationCenter.defaultCenter().removeObserver(self, name: ReachabilityChangedNotification, object: networkChecker)
    }
    
    //MARK: Network Operations
    func reachabilityChanged(note: NSNotification) {
        
        checkAndSyncPending()
    }
    
    deinit {
        stopSyncChecker()
    }
}