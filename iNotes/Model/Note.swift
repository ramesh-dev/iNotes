//
//  Note.swift
//  iNotes
//
//  Created by Ramesh Lingappa on 9/24/15.
//  Copyright © 2015 Ramesh. All rights reserved.
//

import Foundation

class Note : NSObject, NSCoding {
    
    var id : String
    
    var title : String
    
    var dbRev : String?
    var createdAt : Int = 0
    var modifiedAt : Int = 0
    
    // temp property to tranfer data, will not be saved
    var content : String = ""
    
    var extFileName : String {
    
        let name = title.trim().stringByReplacingOccurrencesOfString(" ", withString: "-")
        return "\(name).txt"
    }
    
    var localFileName : String {
        return "\(id).txt"
    }
    
    init(_ id : String, title : String) {
        
        self.id = id
        self.title = title
    }
    
    convenience init(title : String){
        self.init(Utils.randomString(20), title: title)
    }
    
    convenience required init?(coder decoder: NSCoder) {
        
        guard let id = decoder.decodeObjectForKey("id") as? String,
              let title = decoder.decodeObjectForKey("title") as? String
        else { return nil }
        
        self.init(id, title :title)
        
        self.dbRev = decoder.decodeObjectForKey("dbRev") as? String
        
        self.createdAt = decoder.decodeIntegerForKey("createdAt")
        self.modifiedAt = decoder.decodeIntegerForKey("modifiedAt")
        
    }
    
    func updateTimeStamp(){
        
        if createdAt <= 0 {
            createdAt = Int(NSDate().timeIntervalSince1970)
            modifiedAt = createdAt
            return
        }
        self.modifiedAt = Int(NSDate().timeIntervalSince1970)
    }
    
    //MARK: coder
    func encodeWithCoder(coder: NSCoder) {
        
        coder.encodeObject(self.id, forKey: "id")
        coder.encodeObject(self.title, forKey: "title")
                
        coder.encodeInteger(self.createdAt, forKey: "createdAt")
        coder.encodeInteger(self.modifiedAt, forKey: "modifiedAt")
        
        if dbRev != nil {
            coder.encodeObject(self.dbRev, forKey: "dbRev")
        }
    }
}