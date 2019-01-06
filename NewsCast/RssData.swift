//
//  RssData.swift
//  MyApp
//
//  Created by Jose Adams on 2018/10/15.
//  Copyright © 2018 Jose Adams. All rights reserved.
//

import UIKit

class RssData: NSObject {
    
    /*ATTRIBUTES*/
    private var _tick: Bool?;
    private var _sid: Int32?;
    private var _parent: String?;
    private var _title: String?;
    private var _link: String?;
    private var _description: String?;
    private var _pubdate: String?;
    private var _copyright: String?;
    private var _category: String?;
    private var _mark: String?;
    private var _script: String?;
    private var _media: String?;
    
    /*constructor*/
    
    /*GETTER / SETTER*/
    var Tick: Bool?
    {
        get
        {
            return _tick;
        }
        set
        {
            _tick = newValue;
        }
    }
    
    var Sid: Int32?
    {
        get
        {
            return _sid;
        }
        set
        {
            _sid = newValue;
        }
    }
    
    var Parent: String?
    {
        get
        {
            return _parent;
        }
        set
        {
            _parent = newValue;
        }
    }
    
    var Title: String?
    {
        get
        {
            return _title;
        }
        set
        {
            _title = newValue;
        }
    }
    
    var Link: String?
    {
        get
        {
            return _link;
        }
        set
        {
            _link = newValue;
        }
    }
    
    var Description: String?
    {
        get
        {
            return _description;
        }
        set
        {
            _description = newValue;
        }
    }
    
    var PubDate: String?
    {
        get
        {
            return _pubdate;
        }
        set
        {
            _pubdate = newValue;
        }
    }
    
    var Copyright: String?
    {
        get
        {
            return _copyright;
        }
        set
        {
            _copyright = newValue;
        }
    }
    
    var Category: String?
    {
        get
        {
            return _category;
        }
        set
        {
            _category = newValue;
        }
    }
    
    var Mark: String?
    {
        get
        {
            return _mark;
        }
        set
        {
            _mark = newValue;
        }
    }
    
    var Script: String?
    {
        get
        {
            return _script;
        }
        set
        {
            _script = newValue;
        }
    }
    
    var Media: String?
    {
        get
        {
            return _media;
        }
        set
        {
            _media = newValue;
        }
    }
    
    /*ADVANCED GETTER*/
    
    func toDictionary(Table table: String) -> Dictionary<String, Any>
    {
        var dict = Dictionary<String, Any>()
        
        dict["parent"] = _parent ?? "";
        print("RssData -->  parent: \(dict["parent"]!)");
        dict["title"] = _title ?? "";
        print("RssData -->  title: \(dict["title"]!)");
        dict["link"] = _link ?? "";
        print("RssData -->  link: \(dict["link"]!)");
        dict["description"] = _description ?? "";
        print("RssData -->  description: \(dict["description"]!)");
        dict["pubdate"] = _pubdate ?? "";
        print("RssData -->  pubdate: \(dict["pubdate"]!)");
        
        switch(table)
        {
        case DaoHandle.FEEDLIST:
            dict["copyright"] = _copyright ?? "";
            print("RssData -->  copyright: \(dict["copyright"]!)");
            break;
        case DaoHandle.ITEMLIST:
            dict["category"] = _category ?? "";
            print("RssData -->  category: \(dict["category"]!)");
            dict["media"] = _media ?? "";
            print("RssData -->  media: \(dict["media"]!)");
            dict["script"] = _script ?? "";
            print("RssData -->  script: \(dict["script"]!)");
            break;
        default:
            break;
        }
        
        dict["mark"] = _mark ?? "";
        print("RssData -->  mark: \(dict["mark"]!)");
        
        let size = dict.count;
        print("RssData --> dict's size: \(size)");
        
        return dict;
    }
    
    /*ADVANCED SETTER*/
    
    func fromFM(ResultSet resultSet: FMResultSet)
    {
        let count: Int32 = resultSet.columnCount();
        
        var index: Int32 = 0;
        
        while(index < count)
        {
            let name: String = resultSet.columnName(for: index)!;
            
            index += 1;
            
            switch(name)
            {
            case "sid":
                _sid = resultSet.int(forColumn: name);
                print("RssData -->  \(name): \(_sid ?? -1)");
                break;
            case "parent":
                _parent = resultSet.string(forColumn: name) ?? nil;
                print("RssData -->  \(name): \(_parent ?? "")");
                break;
            case "copyright":
                _copyright = resultSet.string(forColumn: name) ?? nil;
                print("RssData -->  \(name): \(_copyright ?? "")");
                break;
            case "category":
                _category = resultSet.string(forColumn: name) ?? nil;
                print("RssData -->  \(name): \(_category ?? "")");
                break;
            case "title":
                _title = resultSet.string(forColumn: name) ?? nil;
                print("RssData -->  \(name): \(_title ?? "")");
                break;
            case "link":
                _link = resultSet.string(forColumn: name) ?? nil;
                print("RssData -->  \(name): \(_link ?? "")");
                break;
            case "description":
                _description = resultSet.string(forColumn: name) ?? nil;
                print("RssData -->  \(name): \(_description ?? "")");
                break;
            case "pubdate":
                _pubdate = resultSet.string(forColumn: name) ?? nil;
                print("RssData -->  \(name): \(_pubdate ?? "")");
                break;
            case "script":
                _script = resultSet.string(forColumn: name) ?? nil;
                print("RssData -->  \(name): \(_script ?? "")");
                break;
            case "media":
                _media = resultSet.string(forColumn: name) ?? nil;
                print("RssData -->  \(name): \(_media ?? "")");
                break;
            case "mark":
                _mark = resultSet.string(forColumn: name) ?? nil;
                print("RssData -->  \(name): \(_mark ?? "")");
                break;
            default:
                break;
            }
        }
    }
}
