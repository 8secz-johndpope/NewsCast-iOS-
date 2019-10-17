//
//  File.swift
//  NewsCast
//
//  Created by Jose Adams on 2018/10/25.
//  Copyright © 2018 Jose Adams. All rights reserved.
//

import UIKit

/*
 *  https://stackoverflow.com/questions/33228403/segue-to-uiviewcontroller-without-initializing-a-new-object
 *  https://stackoverflow.com/questions/41136597/create-singleton-of-a-viewcontroller-in-swift-3
 */

class ViewControllerManager
{
    
    /*attributes*/
    
    private var StoredTabBarVC: UITabBarController?
    private var StoredReloadVC: ReloadViewController?
    private var StoredPlayerVC: PlayerViewController?
    private var StoredSubscribeVC: SubscribeViewController?
    private var StoredData: RssData?
    
    /*constructor*/
    
    private init()
    {
        print("a whole new ViewControllerManager object");
    }
    
    static let Bridge = ViewControllerManager()
    
    /*property / getter */
    
    var Data: RssData?
    {
        get
        {
            return StoredData;
        }
        set
        {
            StoredData = newValue;
        }
    }
    
    var TabBarVC: UITabBarController
    {
        if self.StoredTabBarVC == nil
        {
            print("TabBarVC is a new member")
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            self.StoredTabBarVC = storyboard.instantiateViewController(withIdentifier: "TabBarVC") as? UITabBarController
        }
        else
        {
            print("TabBarVC is a existed member");
        }
        
        let value = self.StoredTabBarVC!.hashValue;
        print("TabBarVC's HashValue: \(value)")
        
        return self.StoredTabBarVC!;
    }
    
    var ReloadVC: ReloadViewController
    {
        if self.StoredReloadVC == nil
        {
            print("ReloadVC is a new member")
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            self.StoredReloadVC = storyboard.instantiateViewController(withIdentifier: "ReloadVC") as? ReloadViewController
        }
        else
        {
            print("ReloadVC is a existed member");
        }
    
        let value = self.StoredReloadVC!.hashValue;
        print("ReloadVC's HashValue: \(value)")
        
        return self.StoredReloadVC!
    }
    
    var PlayerVC: PlayerViewController
    {
        if self.StoredPlayerVC == nil
        {
            print("PlayerVC is a new member")
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            self.StoredPlayerVC = storyboard.instantiateViewController(withIdentifier: "PlayerVC") as? PlayerViewController
        }
        else
        {
            print("PlayerVC is a existed member");
        }
        
        let value = self.StoredPlayerVC!.hashValue;
        print("PlayerVC's HashValue: \(value)")
        
        return self.StoredPlayerVC!;
    }
    
    var SubscribeVC: SubscribeViewController
    {
        if self.StoredSubscribeVC == nil
        {
            print("SubscribeVC is a new member")
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            self.StoredSubscribeVC = storyboard.instantiateViewController(withIdentifier: "SubscribeVC") as? SubscribeViewController
        }
        else
        {
            print("SubscribeVC is a existed member");
        }
        
        let value = self.StoredSubscribeVC!.hashValue;
        print("SubscribeVC's HashValue: \(value)")
        
        return self.StoredSubscribeVC!;
    }
    
}
