//
//  NewNoteViewController.swift
//  iNotes
//
//  Created by Ramesh Lingappa on 9/26/15.
//  Copyright © 2015 Ramesh. All rights reserved.
//

import UIKit
import MBProgressHUD

protocol NoteDetailsDelegate : class {
    
    func noteDetailsDidTapClose()
    
    func noteDetails(didSaveNote note: Note)
    func noteDetails(didDeleteNote note: Note)
}

class NoteDetailsViewController: UIViewController {
    
    // outlets
    @IBOutlet weak var header: UINavigationItem!
    
    @IBOutlet weak var noteTextView: UITextView!
    
    @IBOutlet weak var deleteBtn: UIButton!
    
    @IBOutlet weak var noteTextViewBottomConstraint: NSLayoutConstraint!
    
    // custom properties
    var alertHud : MBProgressHUD?
    
    weak var delegate : NoteDetailsDelegate?
    
    var note = Note("", title : "")
    
    private(set) var edited = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        alertHud =  MBProgressHUD(view: self.view)
        self.view.addSubview(alertHud!)
        
        self.registerKeyboardNotifications()
        
        // new note
        if note.id.isEmpty {
            
            header.title = "New Note"
            header.leftBarButtonItem?.title = "Cancel"
            
            deleteBtn.hidden = true
            
            Utils.delay(0.15, queue: dispatch_get_main_queue(), closure: {[unowned self] () -> () in
                self.noteTextView.becomeFirstResponder()
            })
            
        }else {
            // existing note
            
            deleteBtn.hidden = false
            
            header.title = note.title
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { [unowned self] () -> Void in
                
                //TODO yet to setup alert for error
                self.note.content =  NoteService.sharedInstance.readNoteContentFromFile(self.note.localFileName) ?? ""
                
                dispatch_async(dispatch_get_main_queue(), { [unowned self] () -> Void in
                    self.noteTextView.text = self.note.content
                })
            })
        }
    }
    
    @IBAction func backBtnAct(sender: AnyObject) {
        
        self.view.endEditing(true)

        if isEdited() {
            let alertView = UIAlertController(title: "Dicard Changes", message: "Sure want to dicard changes?", preferredStyle: UIAlertControllerStyle.Alert)
            
            let okBtn = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { (alertAction) -> Void in
                delegate?.noteDetailsDidTapClose()
            })
            
            let cancelBtn = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler:nil)
            
            alertView.addAction(cancelBtn)
            alertView.addAction(okBtn)
            
            self.presentViewController(alertView, animated: true, completion: nil)
            
            return
        }
        
        delegate?.noteDetailsDidTapClose()
    }
    
    @IBAction func saveBtnAct(sender: AnyObject) {
        
        self.view.endEditing(true)
        
        if !isEdited() {
            alertHud?.showText("No changes to save!", delay: 2)
            return
        }
        
        note.content = noteTextView.text
        
        let title = NoteService.sharedInstance.extractNoteTitle(note.content, maxLength: 30)
        if title == nil {
            alertHud?.showText("Please enter few characters to save!", delay : 2)
            return
        }
        
        note.title = title!
        note.updateTimeStamp()
        
        if note.id.isEmpty  {
            note.id = Utils.randomString(20)
        }
    
        let saved = NoteService.sharedInstance.saveNote(note)
        if !saved {
            alertHud?.showText("Unable to save changes", detailMsg: "Please try again!", delay: 2)
            return
        }
        
        Utils.delay(0.2, queue: dispatch_get_main_queue()) { () -> () in
            delegate?.noteDetails(didSaveNote: note)
        }
    }
    
    
    @IBAction func deleteBtnAct(sender: AnyObject) {
        
        let alertView = UIAlertController(title: "Delete Note", message: "Sure want to delete this note? this action cannot be reverted", preferredStyle: UIAlertControllerStyle.Alert)
        
        let okBtn = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: { [unowned self] (alertAction) -> Void in
            
            if !NoteService.sharedInstance.deleteNote(self.note) {
                
                self.alertHud?.showText("Unable to delete note", detailMsg: "Please try again", delay: 2)
            }else {
                
                self.alertHud?.showText("Note Deleted Successfully!", delay: 1.5)
                
                Utils.delay(1.5, queue: dispatch_get_main_queue(), closure: { () -> () in
                    self.delegate?.noteDetails(didDeleteNote: self.note)
                })
            }
        })
        
        let cancelBtn = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler:nil)
        
        alertView.addAction(cancelBtn)
        alertView.addAction(okBtn)
        
        self.presentViewController(alertView, animated: true, completion: nil)
    }
    
    //MARK: Notes
    
    // basic check
    func isEdited() -> Bool {
        return noteTextView.text != note.content
    }
    
    //MARK: KeyBoard Events
    
    func registerKeyboardNotifications() {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name:UIKeyboardWillHideNotification, object: nil)
    }
    
    func unregisterKeyboardNotifications(){
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIKeyboardDidHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification : NSNotification){
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey])?.CGRectValue {
            
            let rect = self.view.convertRect(keyboardSize, fromView: nil)
            
            // 40 represents delete button height offset
            noteTextViewBottomConstraint.constant = rect.size.height - 40
        }
    }
    
    func keyboardWillHide(notification : NSNotification) {
        self.noteTextViewBottomConstraint.constant = deleteBtn.hidden ? -40 : 5
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}





