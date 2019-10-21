//
//  HeadArrayTableViewDelegate.swift
//  NewsCast
//
//  Created by Jose Adams on 2018/10/22.
//  Copyright © 2018 Jose Adams. All rights reserved.
//

import UIKit

class ChanArrayTableViewAdapter: NSObject, UITableViewDelegate, UITableViewDataSource
{
    /*
    *   https://stackoverflow.com/questions/39391755/create-custom-uitableview-class
    *   https://hackernoon.com/uitableview-leading-trailing-swipe-actions-in-ios-11-18cb1f267f8a
    *   https://www.andrewcbancroft.com/2015/07/16/uitableview-swipe-to-delete-workflow-in-swift/
    *   https://www.youtube.com/watch?v=zAWO9rldyUE
    *   https://www.youtube.com/watch?v=YwE3_hMyDZA
    *   https://medium.com/%E5%BD%BC%E5%BE%97%E6%BD%98%E7%9A%84-swift-ios-app-%E9%96%8B%E7%99%BC%E6%95%99%E5%AE%A4/b69a65f1efb
    */
    
    /*Attributes*/
    
    private var _array: [RssData];
    private var _rows: Int;
    
    /*Constructor*/
    
    init(_ array: [RssData])
    {
        _array = array;
        
        _rows = _array.count;
        
        print("ChanArrayTableView --> total number of showed cells: \(_rows)");
    }
    
    /* Getter / Setter */
    
    /*
    *   a block output for ouside world to use, a closure expression
    */
    
    var DidSelectRow: ( (_ data: RssData) -> Void )?
    var WillDeleteRow: ( (_ data: RssData) -> Void )?
    var DidDeleteRow: ( (_ data: RssData) -> Void )?
    
    /* Data Source */
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return _rows;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let myIndex = indexPath.row;
        
        print("ChanArrayTableView --> showed cell's index: \(myIndex)");
        
        let myData: RssData = _array[myIndex];
        
        let myTitle: String = myData.Title ?? "";
        let myDescription: String = myData.Description ?? "";
        let myPubDate: String = myData.PubDate ?? "";
        
        print("ChanArrayTableView --> showed cell's title: \(myTitle)");
        print("ChanArrayTableView --> showed cell's description: \(myDescription)");
        print("ChanArrayTableView --> showed cell's pubdate: \(myPubDate)");
        
        /* to combine cell's xib file and class fill all together*/
        let cell = Bundle.main.loadNibNamed("ChanArrayTableViewCell", owner: self, options: nil)?.first as! ChanArrayTableViewCell
        
        cell.title?.text = myTitle;
        cell.desc?.text = myDescription;
        cell.date?.text = myPubDate;
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let height = CGFloat(80.0);
        
        return height;
    }
    
    /* Delegates */
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let myIndex = indexPath.row;
        let myData: RssData = _array[myIndex];
        let myTitle = myData.Title;
        
        print("ChanArrayTableView --> select: \(myTitle!)");

        //let myCell = tableView.cellForRow(at: indexPath as IndexPath)  as! ChanArrayTableViewCell
        
        if let didSelect = DidSelectRow    // pass to block
        {
            didSelect(myData);  // the outsider aka ViewController will implement a dedicated function to response this...
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let myIndex = indexPath.row;
        let myData = _array[myIndex];
        let myTitle = myData.Title;
        let myMark = myData.Mark ?? DaoHandle.UNSET;
        
        print("ChanArrayTableView --> leading swipe: \(myTitle!) ~ \(myMark)");
        
        //let myCell = tableView.cellForRow(at: indexPath as IndexPath)  as! ChanArrayTableViewCell
        
        if let willDelete = WillDeleteRow  //pass to block
        {
            willDelete(myData); // the outsider aka ViewController will implement a dedicated function to response to this...
        }
        
        var myAction: UIContextualAction?;
        
        if myMark == DaoHandle.SET
        {
            myAction = UIContextualAction(style: UIContextualAction.Style.normal, title: "") { (action, view, handler) in
                
                print("ChanArrayTableView --> did delete: \(myTitle!)");
                
                handler(true);  //reserved items
            }
            
            myAction!.backgroundColor = UIColor.lightGray;
        }
        else
        {
            myAction = UIContextualAction(style: UIContextualAction.Style.normal, title: "X DELETE") { (action, view, handler) in
                
                print("ChanArrayTableView --> did delete: \(myTitle!)");
                
                if let didDelete = self.DidDeleteRow //pass to block
                {
                    didDelete(myData);
                    
                    handler(true);
                }
            }
            
            myAction!.backgroundColor = UIColor.orange;
        }
        
        let myConfiguration = UISwipeActionsConfiguration(actions: [myAction!]);
        
        return myConfiguration; //looks like registering this action...
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let myIndex = indexPath.row;
        let myData = _array[myIndex];
        let myTitle = myData.Title;
        
        print("ChanArrayTableView --> trailing swipe: \(myTitle!)");
        
        let noAction = UIContextualAction(style: UIContextualAction.Style.normal, title: "") { (action, view, handler) in

            print("ChanArrayTableView --> no action: \(myTitle!)");

            handler(true);
        }
        
        noAction.backgroundColor = UIColor.lightGray;
        
        let myConfiguration = UISwipeActionsConfiguration(actions: [noAction]);
        
        return myConfiguration;
    }
    
}
