//
//  ItemArrayTableView.swift
//  NewsCast
//
//  Created by Jose Adams on 2018/10/26.
//  Copyright © 2018 Jose Adams. All rights reserved.
//

import UIKit

class ItemArrayTableViewAdapter: NSObject, UITableViewDelegate, UITableViewDataSource
{
    
    /*Attributes*/
    
    private var _array: [RssData];
    private var _rows: Int;
    
    /*Constructor*/
    
    init(_ array: [RssData])
    {
        _array = array;
        
        _rows = _array.count;
        
        print("ItemArrayTableView --> total number of showed cells: \(_rows)");
    }
    
    /* Getter / Setter */
    
    /*
     *   a delegational output for ouside world to use
     */
    
    var DidSelectRow: ( (_ data: RssData) -> Void )?   /// <-- pretty much lika a closure expression
    var WillLikeRow: ( (_ data: RssData) -> Void )?   /// <-- pretty much lika a closure expression
    var DidLikeRow: ( (_ data: RssData) -> Void )?   /// <-- pretty much lika a closure expression
    var WillUnLikeRow: ( (_ data: RssData) -> Void )?   /// <-- pretty much lika a closure expression
    var DidUnLikeRow: ( (_ data: RssData) -> Void )?   /// <-- pretty much lika a closure expression
    
    /* Data Source */
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return _rows;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let myIndex = indexPath.row;
        
        print("ItemArrayTableView --> showed cell's index: \(index)");
        
        let myData: RssData = _array[myIndex];
        
        let myTitle: String = myData.Title ?? "";
        let myParent: String = myData.Parent ?? "";
        let myCategory: String = myData.Category ?? "";
        let myPubDate: String = myData.PubDate ?? "";
        
        print("ItemArrayTableView --> showed cell's title: \(myTitle)");
        print("ItemArrayTableView --> showed cell's parent: \(myParent)");
        print("ItemArrayTableView --> showed cell's category: \(myCategory)");
        print("ItemArrayTableView --> showed cell's pubdate: \(myPubDate)");
        
        /* to combine cell's xib file and class fill all together*/
        let cell = Bundle.main.loadNibNamed("ItemArrayTableViewCell", owner: self, options: nil)?.first as! ItemArrayTableViewCell
        
        cell.title?.text = myTitle;
        cell.parent?.text = myParent;
        cell.cate?.text = myCategory;
        cell.date?.text = myPubDate;
        
        return cell;
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let height = CGFloat(80.0);
        
        return height;
    }
    
    /* Delegates */
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let myIndex = indexPath.row
        let myData = _array[myIndex];
        let myTitle = myData.Title;
        
        print("ItemArrayTableView --> select: \(myTitle!)");

        //let cell = tableView.cellForRow(at: indexPath as IndexPath)  as! ItemArrayTableViewCell
        
        if let didSelect = DidSelectRow
        {
            didSelect(myData)
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let myIndex = indexPath.row;
        let myData = _array[myIndex];
        let myTitle = myData.Title;
        let myMark = myData.Mark ?? DaoHandle.UNSET;
        
        print("ItemArrayTableView --> leading swipe: \(myTitle!) ~ \(myMark)");
        
        //let myCell = tableView.cellForRow(at: indexPath as IndexPath)  as! ItemArrayTableViewCell
        
        var myAction: UIContextualAction?;
        
        if myMark == DaoHandle.SET
        {
            if let willUnLike = WillUnLikeRow  //pass to block
            {
                willUnLike(myData); // the outsider aka ViewController will implement a dedicated function to response to this...
            }
            
            myAction = UIContextualAction(style: UIContextualAction.Style.normal, title: "♡ UNLIKE") { (action, view, handler) in
                
                print("ItemArrayTableView --> did UNLike: \(myTitle!)");
                
                if let didUnLike = self.DidUnLikeRow //pass to block
                {
                    didUnLike(myData);
                    
                    handler(true);
                }
            }
            
            myAction!.backgroundColor = UIColor.blue;
        }
        else
        {
            if let willLike = WillLikeRow  //pass to block
            {
                willLike(myData); // the outsider aka ViewController will implement a dedicated function to response to this...
            }
            
            myAction = UIContextualAction(style: UIContextualAction.Style.normal, title: "♥ LIKE") { (action, view, handler) in
                
                print("ItemArrayTableView --> did Like: \(myTitle!)");
                
                if let didLike = self.DidLikeRow //pass to block
                {
                    didLike(myData);
                    
                    handler(true);
                }
            }
            
            myAction!.backgroundColor = UIColor.red;
        }
        
        let myConfiguration = UISwipeActionsConfiguration(actions: [myAction!]);
        return myConfiguration; //looks like registering this action...
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let myIndex = indexPath.row;
        let myData = _array[myIndex];
        let myTitle = myData.Title;
        
        print("ItemArrayTableView --> trailing swipe: \(myTitle!)");
        
        let noAction = UIContextualAction(style: .normal, title: "") { (action, view, handler) in
            
            print("ItemArrayTableView --> no action: \(myTitle!)");
            
            handler(true);  //force it to be done
        }
        
        noAction.backgroundColor = UIColor.lightGray;
        
        let myConfiguration = UISwipeActionsConfiguration(actions: [noAction]);
        
        return myConfiguration;
    }
}
