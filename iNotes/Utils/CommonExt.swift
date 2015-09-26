//
//  CommonExt.swift
//  iNotes
//
//  Created by Ramesh Lingappa on 9/26/15.
//  Copyright © 2015 Ramesh. All rights reserved.
//

import Foundation

extension NSBundle {
    
    class var applicationVersionNumber: String {
        if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Version Number Not Available"
    }
    
    class var applicationBuildNumber: String {
        if let build = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as? String {
            return build
        }
        return "Build Number Not Available"
    }
}

extension UIViewController {
    
    public func  initViewControllerForIdentifier(id : String) -> UIViewController? {
        
        return self.storyboard!.instantiateViewControllerWithIdentifier(id)
    }
}

extension String {
    
    public func trim() -> String {
        return self.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
    }
    
    public func trimWhiteSpaceAndNewLine() -> String {
        return self.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
    }
    
    func indexOf(target: String) -> Int {
        
        if let range = self.rangeOfString(target) {
            return self.startIndex.distanceTo(range.startIndex)
        } else {
            return -1
        }
    }
    
    func indexOf(target: String, startIndex: Int) -> Int {
        
        let startRange = self.startIndex.advancedBy(startIndex)
        
        let range = self.rangeOfString(target, options: NSStringCompareOptions.LiteralSearch, range: Range<String.Index>(start: startRange, end: self.endIndex))
        
        if let range = range {
            return self.startIndex.distanceTo(range.startIndex)
        } else {
            return -1
        }
    }
    
    func lastIndexOf(target: String) -> Int {
        var index = -1
        var stepIndex = self.indexOf(target)
        while stepIndex > -1 {
            
            index = stepIndex
            if stepIndex + target.characters.count < self.characters.count {
                
                stepIndex = indexOf(target, startIndex: stepIndex + target.characters.count)
            } else {
                stepIndex = -1
            }
        }
        return index
    }
}