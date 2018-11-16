//
//  XmlHandle.swift
//  MyApp
//
//  Created by Jose Adams on 2018/10/15.
//  Copyright © 2018 Jose Adams. All rights reserved.
//

import UIKit

class XmlHandle: NSObject, XMLParserDelegate{
    
    /*ATTRIBUTES*/
    
    private var _urlSource: String?;
    private var _xmlParser: XMLParser?;
    private var _workItem: DispatchWorkItem?;
    private var _rssData: RssData?;
    private var _rssDataArray: [RssData]?;
    
    private var _text = "";
    private var _parentOfItems = "";
    
    private var _isRssHead = false;
    private var _isRssItem = false;
    private var _response = "";
    private let Notice = NotificationCenter.default;
    
    
    /*constructor*/
    
    init(Url url: String, Response response: String)
    {
        _urlSource = url;
        _response = response;
    }
    
    /* GETTER / SETTER */
    
    var RssDataArray: [RssData]
    {
        return _rssDataArray!;
    }
    
    var UrlSource: String?
    {
        get
        {
            return _urlSource;
        }
        set
        {
            _urlSource = newValue;
        }
    }
    
    var Response: String
    {
        get
        {
            return _response;
        }
        set
        {
            _response = newValue;
        }
    }
    
    /*METHOD*/
    
    private func throwMessage(_ message: String)
    {
        Notice.post(name:Notification.Name(rawValue: _response), object: nil, userInfo: ["XmlHandle":message])
    }
    
    /*
     *  https://developer.apple.com/documentation/dispatch/dispatch_block_flags_t
     *  https://docs.swift.org/swift-book/LanguageGuide/AccessControl.html
     *  https://developer.apple.com/documentation/dispatch/dispatchworkitem
     */
    
    func proceed()
    {
        if _workItem == nil
        {
            print("XmlHandle --> making a shared WorkItem");
            
            _workItem = DispatchWorkItem(block: {
                
                var message = "";
                
                let url = URL(string: self._urlSource!);
                
                self._xmlParser = XMLParser(contentsOf: url!)
                
                self._xmlParser!.delegate = self;
                
                if self._xmlParser!.parse() // Parse the XML
                {
                    print("XmlHandle --> parsed!");
                    
                    let value = self._rssDataArray!.hashValue;
                    
                    print("XmlHandle --> RssDataArray's HashValue, phase 2: \(value)");
                    
                    let size = self._rssDataArray!.count;
                    
                    print("XmlHandle --> RssDataArray's size, phase 2: \(size)");
                    
                    if size > 0
                    {
                        message = "FETCHED"
                    }
                    else
                    {
                        message = "EMPTY"
                    }
                }
                else
                {
                    print("XmlHandle --> parsed, but failed!")
                    
                    message = "FAILED"
                }
                
                self._xmlParser = nil;
                
                self.throwMessage(message);
            });
            
            print("XmlHandle --> perfoming a shared WorkItem");
            
            _workItem!.perform();
            
        }
        else
        {
            print("XmlHandle --> the shared WrokItem is occupied");
        }
    }
    
    func cancel()
    {
        if _xmlParser == nil
        {
            print("XmlHandle --> the Xml Parser is empty");
        }
        else
        {
            _xmlParser!.abortParsing();
            
            _xmlParser = nil;
        }
        
        if _workItem == nil
        {
            print("XmlHandle --> the shared WrokItem is empty");
        }
        else
        {
            _workItem!.cancel();
            
            _workItem = nil;
        }
    }
    
    /* Delegations */
    
    internal func parserDidStartDocument(_ parser: XMLParser) {
        
        print("XmlHandle --> start!");
        
        _isRssHead = false;
        _isRssItem = false;
    }
    
    internal func parserDidEndDocument(_ parser: XMLParser) {
        
        print("XmlHandle --> end!");
        
        let value = self._rssDataArray!.hashValue;
        
        print("XmlHandle --> RssDataArray's HashValue, phase 1: \(value)");
        
        let size = self._rssDataArray!.count;
        
        print("XmlHandle --> RssDataArray's size, phase 1: \(size)");
    }
    
    internal func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error)
    {
        print("XmlHandle --> error: ", parseError);
    }
    
    internal func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:])
    {
        _text = "";
        
        switch (elementName)
        {
        case "channel":
            /*
             *  To renew a RssData Object for coming HeadData
             *  To renew a RssDataArray Object for coming RssDataList
             * */
            if(!_isRssHead)
            {
                _isRssHead = true;
                
                _rssData = RssData();
                
                _rssDataArray = [RssData]();   /// <-- start a whole new Array
            }
            break;
        case "item":
            if(_isRssHead)
            {
                _isRssHead = false;   //to give way for item...
                
                _parentOfItems = _rssData!.Title!;  //head data's title becomes coming items' parent...
                
                print("XmlHandle --> Parsing, ItemData's Parent To Be: \(_parentOfItems)");
                
                _rssData!.Parent = _rssData!.Link;
                _rssData!.Link = _urlSource;
                
                let parent: String = _rssData!.Parent!;
                let link: String = _rssData!.Link!;
                
                print("XmlHandle --> Parsing, HeadData's Parent: \(parent)");
                print("XmlHandle --> Parsing, HeadData's Link: \(link)");
                
                _rssDataArray!.append(_rssData!);
                
                let size = _rssDataArray!.count;
                
                print("XmlHandle --> Parsing, RssDataArray, size: \(size)");
            }
            /*
             *  To renew a RssData Object for coming ItemData
             * */
            if(!_isRssItem)
            {
                _isRssItem = true;
                
                _rssData = RssData();
            }
            break;
        case "enclosure":
            if(_isRssItem)    // for NHK online radio...
            {
                let link: String = attributeDict["url"]!;
                _rssData!.Link = link;
                print("XmlHandle --> Parsing, Link: " + link);
            }
            break;
        default:
            break;
        }
    }
    
    internal func parser(_ parser: XMLParser, foundCharacters string: String)
    {
        _text += string;
    }
    
    internal func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
    {
        switch(elementName)
        {
        case "item":
            if (_isRssItem)
            {
                _isRssItem = false;
                
                _rssData!.Parent = _parentOfItems;
                
                print("XmlHandle --> Parsing, ItemData's Parent: \(_rssData!.Parent!)");
                
                _rssDataArray!.append(_rssData!);
                
                let size = _rssDataArray!.count;
                
                print("XmlHandle --> Parsing, RssDataArray, size: \(size)");
            }
            break;
        case "title":
            _rssData!.Title = _text;
            print("XmlHandle --> Parsing, Title: \(_rssData!.Title!)");
            break;
        case "link":
            _rssData!.Link = _text;
            print("XmlHandle --> Parsing, Link: \( _rssData!.Link!)");
            break;
        case "description":
            _rssData!.Description = _text;
            print("XmlHandle --> Parsing, Description: \(_rssData!.Description!)");
            break;
        case "category":
            _rssData!.Category = _text;
            print("XmlHandle --> Parsing, Category: \(_rssData!.Category!)");
            break;
        case "copyright":
            _rssData!.Copyright = _text;
            print("XmlHandle --> Parsing, Copyright: \(_rssData!.Copyright!)");
            break;
        case "lastBuildDate":
            fallthrough;
        case "pubDate":
            var text: String = _text;
            let myFormatter = DateFormatter();
            myFormatter.locale = Locale.current;
            myFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z";
            let myDate: Date = myFormatter.date(from: text)!;
            myFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss";
            text = myFormatter.string(from: myDate);
            _rssData!.PubDate = text;
            print("XmlHandle --> Parsing, PubDate: \(_rssData!.PubDate!)");
            break;
        default:
            break;
        }
        
        _text = "";
    }
    
}
