//
//  EasyArrayTableView.swift
//  NewsCast
//
//  Created by ucom Apple 08 on 2018/11/1.
//  Copyright © 2018年 Jose Adams. All rights reserved.
//

import UIKit

class EasyArrayTableViewAdapter: NSObject, UITableViewDataSource {
    
    
    /*Attributes*/
    
    private var _array: [RssData];
    private var _rows: Int;
    
    /*Constructor*/
    
    init(_ array: [RssData])
    {
        self._array = array;
        
        self._rows = _array.count;
        
        print("EasyArrayTableView --> total number of showed cells: \(_rows)");
    }
    
    /* Data Source */
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return _rows;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let myIndex = indexPath.row;
        
        print("EasyArrayTableView --> showed cell's index: \(myIndex)");
        
        let myData: RssData = _array[myIndex];
        
        let myTitle: String = myData.Title ?? "";
        let myParent: String = myData.Parent ?? "";
        let myCategory: String = myData.Category ?? "";
        let myPubDate: String = myData.PubDate ?? "";
        
        print("EasyArrayTableView --> showed cell's title: \(myTitle)");
        print("EasyArrayTableView --> showed cell's parent: \(myParent)");
        print("EasyArrayTableView --> showed cell's category: \(myCategory)");
        print("EasyArrayTableView --> showed cell's pubdate: \(myPubDate)");
        
        /* to combine cell's xib file and class fill all together*/
        let cell = Bundle.main.loadNibNamed("EasyArrayTableViewCell", owner: self, options: nil)?.first as! EasyArrayTableViewCell
        
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
    
}
