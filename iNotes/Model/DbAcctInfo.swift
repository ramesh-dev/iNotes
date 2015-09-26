//
//  DbAcctInfo.swift
//  iNotes
//
//  Created by Ramesh Lingappa on 9/26/15.
//  Copyright © 2015 Ramesh. All rights reserved.
//

import Foundation

class DBAcctInfo : NSObject, NSCoding {
    
    var email : String
    var userId : String
    
    init(_ email : String, userId : String){
        
        self.email = email
        self.userId = userId
    }
    
    convenience init(accountInfo info : DBAccountInfo){
        
        self.init(info.email, userId: info.userId)
    }
    
    convenience required init?(coder decoder: NSCoder) {
        
        guard let email = decoder.decodeObjectForKey("email") as? String,
              let userId = decoder.decodeObjectForKey("userId") as? String
            else { return nil }
        
        self.init(email, userId: userId)
    }
    
    //MARK: coder
    func encodeWithCoder(coder: NSCoder) {
        
        coder.encodeObject(self.email, forKey: "email")
        coder.encodeObject(self.email, forKey: "userId")

    }
    
}