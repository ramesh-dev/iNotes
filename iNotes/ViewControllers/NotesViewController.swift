//
//  NotesViewController.swift
//  iNotes
//
//  Created by Ramesh Lingappa on 9/26/15.
//  Copyright © 2015 Ramesh. All rights reserved.
//

import UIKit
import MBProgressHUD

class NotesViewController: UIViewController, NoteDetailsDelegate, UITableViewDataSource, UITableViewDelegate {
    
    // outlets
    @IBOutlet weak var notesTableView: UITableView!
    
    @IBOutlet weak var noNotesView: UIView!
    
    // custom properties
    
    private var alertHud : MBProgressHUD?
    
    private(set) var allNotes : [String : Note] = [:]
    
    private var allNotesKey : [String]?
    
    private var activeIndexPath : NSIndexPath?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        alertHud =  MBProgressHUD(view: self.view)
        self.view.addSubview(alertHud!)
        
        notesTableView.tableFooterView = UIView(frame: CGRectZero)
        
        self.loadNotes()
    }
    
    @IBAction func newNoteBtnAct(sender: AnyObject) {
        
        activeIndexPath = nil
        
        let noteVC = initViewControllerForIdentifier("NoteDetailsViewControllerID") as! NoteDetailsViewController
        noteVC.delegate = self
        
        self.presentViewController(noteVC, animated: true, completion: nil)
    }
    
    //MARK: Notes
    
    func loadNotes(){
        
        allNotes = NoteService.sharedInstance.getAllNotes()
        
        toggleActiveView(hasNotes: !allNotes.isEmpty)
        
        allNotesKey = NoteService.sharedInstance.getSortedNoteIds(allNotes)
    }
    
    func toggleActiveView(hasNotes hasNotes : Bool){
        
        noNotesView.hidden = hasNotes
        notesTableView.hidden = !hasNotes
    }
    
    func configureNoteCellForIndexPath(cell : UITableViewCell, indexPath : NSIndexPath) {
        
        let key = allNotesKey![indexPath.row]
        
        if let note = allNotes[key] {
            
            cell.textLabel?.text = note.title
        }
    }
    
    func deleteNote(note : Note){
        
        let alertView = UIAlertController(title: "Delete Note", message: "Sure want to delete this note? this action cannot be reverted", preferredStyle: UIAlertControllerStyle.Alert)
        
        let okBtn = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: {[unowned self] (alertAction) -> Void in
            
            if !NoteService.sharedInstance.deleteNote(note) {
                
                self.alertHud?.showText("Unable to delete note", detailMsg: "Please try again", delay: 2)
            }else {
                
                // self.alertHud?.showText("Note Deleted Successfully!", delay: 1.5)
                self.removeLocalNote(note, removedIndexPath: self.activeIndexPath)
            }
            })
        
        let cancelBtn = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler:nil)
        
        alertView.addAction(cancelBtn)
        alertView.addAction(okBtn)
        
        self.presentViewController(alertView, animated: true, completion: nil)
    }
    
    func removeLocalNote(note : Note, removedIndexPath : NSIndexPath?){
        
        allNotes[note.id] = nil
        allNotesKey = allNotesKey!.filter { $0 != note.id }
        
        if activeIndexPath != nil{
            notesTableView.beginUpdates()
            notesTableView.deleteRowsAtIndexPaths([activeIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
            notesTableView.endUpdates()
            
        }else {
            notesTableView.reloadData()
        }
        
        if allNotes.count == 0 {
            self.toggleActiveView(hasNotes: false)
        }
    }
    
    func promptForDropBoxSync(){
        
        let count = allNotes.count
        if (count == 1 || count == 5) && !DBSession.sharedSession().isLinked() {
            
            Utils.delay(1, queue: dispatch_get_main_queue(), closure: { () -> () in
                let alertView = UIAlertController(title: "Dropbox Sync", message: "Hey there, we got dropbox sync which syncs all notes to your dropbox account!", preferredStyle: UIAlertControllerStyle.Alert)
                
                let okBtn = UIAlertAction(title: "Link Now", style: UIAlertActionStyle.Default, handler: {[unowned self] (alertAction) -> Void in
                    
                    self.tabBarController?.selectedIndex = 1
                    
                    //TODO call link func to avoid extra button action
                })
                
                let cancelBtn = UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel, handler:nil)
                
                alertView.addAction(cancelBtn)
                alertView.addAction(okBtn)
                
                self.presentViewController(alertView, animated: true, completion: nil)
            })
        }
    }
    
    //MARK: NoteDetails Delegates
    
    func noteDetailsDidTapClose() {
        
        if self.presentedViewController != nil {
            self.dismissViewControllerAnimated(true, completion: nil)
        }else {
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func noteDetails(didSaveNote note: Note) {
        
        if allNotes.updateValue(note, forKey: note.id) == nil{
            //new note
            
            allNotesKey?.insert(note.id, atIndex: 0)
            
            if allNotes.count == 1{
                self.toggleActiveView(hasNotes: true)
                
            }
            
            notesTableView.beginUpdates()
            notesTableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
            notesTableView.endUpdates()
            
            promptForDropBoxSync()
            
        }else {
            // existing note updated
            
            allNotesKey = NoteService.sharedInstance.getSortedNoteIds(allNotes)
            
            notesTableView.reloadData()
        }
        
        self.noteDetailsDidTapClose()
    }
    
    func noteDetails(didDeleteNote note: Note){
        
        self.removeLocalNote(note, removedIndexPath: activeIndexPath)
        
        self.noteDetailsDidTapClose()
    }
    
    //MARK: TableView Delegates
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if allNotesKey != nil {
            return allNotesKey!.count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == UITableViewCellEditingStyle.Delete {
            
            let key = allNotesKey![indexPath.row]
            
            if let note = allNotes[key] {
                
                activeIndexPath = indexPath
                self.deleteNote(note)
            }
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("NoteTableViewCellID")!
        
        configureNoteCellForIndexPath(cell, indexPath: indexPath)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let key = allNotesKey![indexPath.row]
        
        if let note = allNotes[key] {
            
            self.activeIndexPath = indexPath
            
            let noteVC = initViewControllerForIdentifier("NoteDetailsViewControllerID") as! NoteDetailsViewController
            
            noteVC.delegate = self
            noteVC.note = note
            
            self.navigationController?.pushViewController(noteVC, animated: true)
        }
    }
    
}
