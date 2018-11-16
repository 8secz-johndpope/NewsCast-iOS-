//
//  ListArrayTableView.swift
//  NewsCast
//
//  Created by Jose Adams on 2018/10/28.
//  Copyright © 2018 Jose Adams. All rights reserved.
//

import UIKit

class ListArrayTableViewAdapter: NSObject, UITableViewDelegate, UITableViewDataSource
{
    /*
     *   https://stackoverflow.com/questions/39391755/create-custom-uitableview-class
     *   https://hackernoon.com/uitableview-leading-trailing-swipe-actions-in-ios-11-18cb1f267f8a
     *   https://www.andrewcbancroft.com/2015/07/16/uitableview-swipe-to-delete-workflow-in-swift/
     *   https://www.youtube.com/watch?v=zAWO9rldyUE
     *   https://www.youtube.com/watch?v=YwE3_hMyDZA
     */
    
    /*Attributes*/
    
    private var _array: [RssData];
    private var _rows: Int;
    
    /*Constructor*/
    
    init(_ array: [RssData])
    {
        _array = array;
        
        _rows = _array.count;
        
        print("ListArrayTableView --> total number of showed cells: \(_rows)");
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
        
        print("ListArrayTableView --> showed cell's index: \(myIndex)");
        
        let myData: RssData = _array[myIndex];
        
        let myTitle: String = myData.Title ?? "";
        let myParent: String = myData.Parent ?? "";
        let myCategory: String = myData.Category ?? "";
        let myPubDate: String = myData.PubDate ?? "";
        
        print("ListArrayTableView --> showed cell's title: \(myTitle)");
        print("ListArrayTableView --> showed cell's parent: \(myParent)");
        print("ListArrayTableView --> showed cell's category: \(myCategory)");
        print("ListArrayTableView --> showed cell's pubdate: \(myPubDate)");
        
        /* to combine cell's xib file and class fill all together*/
        let cell = Bundle.main.loadNibNamed("ListArrayTableViewCell", owner: self, options: nil)?.first as! ListArrayTableViewCell
        
        cell.title?.text = myTitle;
        cell.parent?.text = myParent;
        cell.cate?.text = myCategory;
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
        
        print("ListArrayTableView --> select: \(myTitle!)");
        
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
        
        print("ListArrayTableView --> leading swipe: \(myTitle!) ~ \(myMark)");
        
        //let myCell = tableView.cellForRow(at: indexPath as IndexPath)  as! ChanArrayTableViewCell
        
        if let willDelete = WillDeleteRow  //pass to block
        {
            willDelete(myData); // the outsider aka ViewController will implement a dedicated function to response to this...
        }
        
        let myAction = UIContextualAction(style: UIContextualAction.Style.normal, title: "X DELETE") { (action, view, handler) in
            
            print("ListArrayTableView --> did delete: \(myTitle!)");
            
            if let didDelete = self.DidDeleteRow //pass to block
            {
                didDelete(myData);
                
                handler(true);
            }
        }
        
        myAction.backgroundColor = UIColor.orange;
        
        let myConfiguration = UISwipeActionsConfiguration(actions: [myAction]);
        
        return myConfiguration; //looks like registering this action...
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let myIndex = indexPath.row;
        let myData = _array[myIndex];
        let myTitle = myData.Title;
        
        print("ListArrayTableView --> trailing swipe: \(myTitle!)");
        
        let noAction = UIContextualAction(style: .normal, title: "") { (action, view, handler) in
            
            print("ListArrayTableView --> no action: \(myTitle!)");
            
            handler(true);
        }
        
        noAction.backgroundColor = UIColor.lightGray;
        
        let myConfiguration = UISwipeActionsConfiguration(actions: [noAction]);
        
        return myConfiguration;
    }
}
