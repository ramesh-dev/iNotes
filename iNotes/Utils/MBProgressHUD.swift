//
//  MBProgressHUDExtension.swift
//  FullMobile
//
//  Created by Ramesh Lingappa on 5/4/15.
//  Copyright (c) 2015 FullCreative. All rights reserved.
//

import UIKit

import MBProgressHUD

extension MBProgressHUD {
    
    var tapGestureRecognizer : UITapGestureRecognizer {
        return UITapGestureRecognizer(target: self, action: "hudTapped")
    }
    
    func setupHUD(delay : NSTimeInterval){
        self.removeFromSuperViewOnHide = false
        self.dimBackground = false
        self.detailsLabelFont = self.labelFont
    }
    
    func setDelay(delay : NSTimeInterval) {
        
        self.removeGestureRecognizer(tapGestureRecognizer)
        if delay > 0 {
            self.hide(true,afterDelay: delay)
            self.addGestureRecognizer(tapGestureRecognizer)
        }
    }
    
    func showLoader(msg : String, detailMsg: String = "", delay :NSTimeInterval = 0) {
        
        setupHUD(delay)
        
        setText(msg, detailMsg: detailMsg)
        self.mode = .Indeterminate
        self.show(true)
        setDelay(delay)
        
    }
    
    func showBottomLoader(delay :NSTimeInterval = 0){

        setupHUD(delay)
        setText("")
        self.mode = .Indeterminate
        self.yOffset = Float (self.frame.size.height/2.5)
        self.show(true)
        setDelay(delay)
    }
    
    
    func setText(msg : String, detailMsg: String = ""){
        self.labelText = msg;
        self.detailsLabelText = detailMsg
    }
    
    func showText(msg : String, detailMsg: String = "", delay : NSTimeInterval = 0){
        
        setupHUD(delay)
        self.mode = .Text
        
        setText(msg, detailMsg: detailMsg)
        self.show(true)
        
        setDelay(delay)
    }
    
    func hudTapped(){
        if !self.hidden {
            self.hide(true)
        }
    }
}