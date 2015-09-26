//
//  NoteService.swift
//  iNotes
//
//  Created by Ramesh Lingappa on 9/26/15.
//  Copyright © 2015 Ramesh. All rights reserved.
//

import Foundation

class NoteService {
    
    static let sharedInstance = NoteService()
    
    private init(){ }
    
    private var allNotes : [String : Note]?
    
    private(set) lazy var notesPath  : NSString = {
        
        let path = Utils.documentDir().stringByAppendingPathComponent("Notes")
        
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil)
        } catch {
            // this is fine, we are just making sure directory was created
        }
        
        return path
        }()
    
    // Note CRUD Operations 
    
    func getAllNotes() -> [String : Note]{
        
        if allNotes == nil {
            
            if let data = NSUserDefaults.standardUserDefaults().objectForKey("notes") as? NSData {
                
                if let notes = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String : Note]{
                    allNotes = notes
                }
            }
            
            if allNotes == nil {
                allNotes = [:]
            }
        }
        
        return allNotes!
    }
    
    func getNote(id : String) -> Note?{
        
        return getAllNotes()[id]
    }
    
    func saveNote(note : Note) -> Bool {
        
        if !writeNoteContentToFile(note.localFileName, content: note.content){
            return false
        }
        
        saveNoteMeta(note)
        
        // add to pendingSync
        DBSyncService.sharedInstance.syncNote(note, deleted: false)

        return true
    }
    
    func saveNoteMeta(note : Note){
       
        var allNotes = self.getAllNotes()
        
        allNotes[note.id] = note
        
        saveAllNotes(allNotes)
    }
    
    func saveAllNotes(notes : [String : Note]){
        
        let data = NSKeyedArchiver.archivedDataWithRootObject(notes)
        
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: "notes")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        self.allNotes = notes
    }
    
    func deleteNote(note : Note) -> Bool {
        
        if !deleteNoteContentFile(note.localFileName) {
            return false
        }
        
        var allNotes = self.getAllNotes()
        
        allNotes[note.id] = nil
        
        saveAllNotes(allNotes)
        
        // add to pendingSync
        DBSyncService.sharedInstance.syncNote(note, deleted: true)
    
        return true
    }
    
    
    //MARK: Note File Operations
    func readNoteContentFromFile(fileName : String) -> String?{
        
        let filePath = notesPath.stringByAppendingPathComponent(fileName)
        
        do {
            return try String(contentsOfFile: filePath, encoding: NSUTF8StringEncoding)
        } catch {
            print("unable to read content for path : \(filePath), error : \(error)")
        }
        
        return nil
    }
    
    func writeNoteContentToFile(fileName : String, content : String) -> Bool {
        
        let filePath = notesPath.stringByAppendingPathComponent(fileName)
        
        do {
            try content.writeToFile(filePath, atomically: true, encoding: NSUTF8StringEncoding)
            
            return true
        } catch {
            print("error saving content to path :\(filePath) , error : \(error)")
        }
        
        return false
    }
    
    func deleteNoteContentFile(fileName : String) -> Bool {
        
        let filePath = notesPath.stringByAppendingPathComponent(fileName)
        
        do {
            try NSFileManager.defaultManager().removeItemAtPath(filePath)
            
            return true
            
        } catch let error as NSError {
            
            // file does not exists
            if error.code == 2 {
                return true
            }
        }
        return false
    }
    
    
    func extractNoteTitle(content : String, maxLength : Int) -> String? {
        
        let trimmedContent = content.stringByReplacingOccurrencesOfString("\n", withString: " ").trimWhiteSpaceAndNewLine()
        let len = trimmedContent.characters.count
        
        if len == 0 {
            return nil
        }
        
        if len <= maxLength {
            return trimmedContent
        }
        
        var title = trimmedContent.substringToIndex(trimmedContent.startIndex.advancedBy(maxLength))
        
        let lastIdx = title.lastIndexOf(" ")
        if lastIdx != -1 {
            title = title.substringToIndex(title.startIndex.advancedBy(lastIdx))
        }
        return title
    }
    
    func getSortedNoteIds(notesDict : [String:  Note]) -> [String] {
        
        if !notesDict.isEmpty {
            
            var notes : [Note] = Array(notesDict.values)
            
            notes.sortInPlace({ (a : Note, b : Note) -> Bool in
                a.modifiedAt > b.modifiedAt
            })
            
            return notes.map{ $0.id }
        }
        
        return []
    }
}