//
//  HtmlHandle.swift
//  NewsCast
//
//  Created by Jose Adams on 2018/10/29.
//  Copyright © 2018 Jose Adams. All rights reserved.
//

import UIKit
import SwiftSoup

class HtmlHandle: NSObject
{
    /*ATTRIBUTES*/
    
    private var _rssData: RssData?;
    private var _rssDataArray: [RssData]?;
    
    private var _webLink: String?;
    private var _rawScript: String?;
    private var _webScript: String?;
    private var _webMediaLink: String?;
    private var _webMediaName: String?;
    //private static let  browserAgent = "Mozilla/5.0 (Linux; Android 7.1.1; MI MAX 2 Build/NMF26F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.83 Mobile Safari/537.36";
    //private static let  browserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.117 Safari/537.36";
    private let Agent = "Mozilla/5.0 (Android 8.0.0; Mobile; rv:62.0) Gecko/62.0 Firefox/62.0";
    
    var timer: Timer?;
    
    private var _response = "";
    private let Notice = NotificationCenter.default;
    private var _workItem: DispatchWorkItem?;
    private var _session: URLSession?;
    private var _dataTask: URLSessionDataTask?;
    
    
    /* CONSTRUCTOR */
    
    init (RssData rssData: RssData, Response response: String)
    {
        _rssData = rssData;
        _response = response;
    }
    
    /* GETTER / SETTER */
    
    var WebLink: String?
    {
        return _webLink;
    }
    
    var WebScript: String?
    {
        return _webScript;
    }
    
    var WebMediaLink: String?
    {
        return _webMediaLink;
    }
    
    var WebMediaFile: String?
    {
        return _webMediaName;
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
    
    // Methods...
    
    private func throwMessage(_ message: String)
    {
        Notice.post(name:Notification.Name(rawValue: _response), object: nil, userInfo: ["HtmlHandle":message])
    }
    
    func proceed()
    {
        var message = "";
        var Script: String?;
        
        if _workItem == nil
        {
            print("HtmlHandle --> making a shared WorkItem");
            
            _workItem = DispatchWorkItem(block: {
                
                self.parser(completionHandler: { (Link, MediaLink, MediaName, rawScript) in
                    
                    if rawScript == nil
                    {
                        if MediaName == nil || MediaLink == nil
                        {
                            message = "NOTHING_FETCHED";
                        }
                        else
                        {
                            message = "ONLY_MEDIA_FETCHED";
                        }
                    }
                    else
                    {
                        if MediaName == nil || MediaLink == nil
                        {
                            message = "ONLY_SCRIPT_FETCHED";
                        }
                        else
                        {
                            message = "COMPLETELY_FETCHED";
                        }
                        
                        Script = rawScript!.trimmingCharacters(in: CharacterSet.whitespaces);
                    }
                    
                    self._webLink = Link
                    self._webMediaLink = MediaLink;
                    self._webMediaName = MediaName;
                    self._webScript = Script;
                    
                    if self._dataTask != nil
                    {
                        self._dataTask!.cancel();
                    }
                    
                    if self._session != nil
                    {
                        self._session!.finishTasksAndInvalidate();
                    }
                    
                    self._session = nil;
                    self._dataTask = nil;
                    
                    self.throwMessage(message);
                })
            
            });
            
            print("HtmlHandle --> perfoming a shared WorkItem");
            
            _workItem!.perform();
        }
        else
        {
            print("HtmlHandle --> the shared WorkItem is occupied");
        }
    }
    
    func cancel()
    {
        if _dataTask == nil
        {
            print("XmlHandle --> the URL Session Data Task is empty");
        }
        else
        {
            _dataTask!.cancel();
            
            _dataTask = nil;
        }
        
        if _session == nil
        {
            print("XmlHandle --> the URL Session is empty");
        }
        else
        {
            _session!.invalidateAndCancel();
            
            _session = nil;
        }
        
        if _workItem == nil
        {
            print("XmlHandle --> the shared WorkItem is empty");
        }
        else
        {
            _workItem!.cancel();
            
            _workItem = nil;
        }
    }
    
    private func parser(completionHandler: @escaping (_ webLink: String?, _ webMediaLink: String?, _ webMediaName: String?, _ webScript: String?) -> Void)
    {
        var pathSeg: String?;
        var link: String?;
        var webLink: String?;
        var webMediaLink: String?;
        var webScript: String?;
        var webMediaName: String?;
        var document: Document?;
        var element: Element?;
        var elements: Elements?;
        var components: URLComponents?;
        var url: URL?;
        
        link = _rssData!.Link ?? "";
        
        print("HtmlHandle --> parsing, raw link: \(link!)");
        
        if link == ""
        {
            print("HtmlHandle --> parsing, raw link is invalid");
            
            completionHandler(webLink, webMediaLink, webMediaName, webScript);
            
            return;
        }
        
        components = URLComponents(string: link!);
        
        let scheme = components!.scheme ?? "";
        let host = components!.host ?? "";
        let path = components!.path ;
        
        print("HtmlHandle --> parsing, scheme: \(scheme)");
        print("HtmlHandle --> parsing, host: \(host)");
        print("HtmlHandle --> parsing, path: \(path)");
        
        if(host == "")
        {
            print("HtmlHandle --> parsing, host is invalid");
            
            completionHandler(webLink, webMediaLink, webMediaName, webScript);
            
            return;
        }
        
        switch (host)
        {
        case "www.fnn-news.com":
            /*
             *  script source: http://www.fnn-news.com/sp/news/headlines/articles/CONN00401204.html
             *  hint from description: http://www.fnn-news.com/news/jpg/sn2018091813_51.jpg
             *  player source: https://ios-video.fnn-news.com/mpeg/sn2018091813_hd_300.mp4
             * */
            if let items = components!.queryItems
            {
                for item in items
                {
                    if item.name == "url"
                    {
                        link = item.value ?? "";
                    }
                }
            }
            if link!.contains("localtime")
            {
                link = link!.replacingOccurrences(of: "localtime", with: "localtime/sp");
                
                webLink = "http://" + host + link!;
            }
            else
            {
                webLink = "http://" + host + "/sp/" + link!;
            }
            print("HtmlHandle --> parsing, clean link: \(webLink!)");
            /*
             *  to creat a web media link
             */
            if webLink!.contains("localtime")
            {
                print("HtmlHandle --> parsing, not yet supported");
                
                completionHandler(webLink, webMediaLink, webMediaName, webScript);
                
                return
            }
            link = _rssData?.Description ?? "";
            do
            {
                document = try SwiftSoup.parse(link!);
                elements = try document?.getElementsByTag("img");
                link = try elements?.attr("src") ?? "";
                url = URL(string: link!);
                pathSeg = url!.pathComponents.last ?? "" ;   // getLastPathSegment();
                if pathSeg != "" && pathSeg!.contains("_51.jpg")
                {
                    pathSeg = pathSeg!.replacingOccurrences(of: "_51.jpg", with: "_hd_300.mp4");
                }
                webMediaLink = "https://ios-video.fnn-news.com/mpeg/" + pathSeg!;
                print("HtmlHandle --> parsing, web media link: \(webMediaLink!)");
                webMediaName = convertURL(webMediaLink);
                print("HtmlHandle --> parsing, web media name: \(webMediaName ?? "")");
            }
            catch Exception.Error(let type, let message)
            {
                print("HtmlHandle --> parsing, error: \(type) / \(message)");
            }
            catch
            {
                print("HtmlHandle --> parsing, error!");
            }
            /*
             *  to creat a web script
             */
            connectURL(webLink!) { (rawContent, errorMessage) in
                
                if let rawContent: String = rawContent
                {
                    do
                    {
                        document = try SwiftSoup.parse(rawContent);
                        /*LOCATE MEDIA*/
                        //                    element = document.selectFirst("#video_html5player");
                        //                    text = element.html();
                        //                    Log.v("HTML_PARSER", "media: " + text);
                        /*LOCATE SCRIPTS*/
                        element = try document!.select("#content > div.mainBox > div.mainNews > div.read").first();
                        let content = try element!.html();
                        webScript = content.replacingOccurrences(of: "<br>", with: " ");
                        print("HtmlHandle --> parsing, script: \(webScript!)");
                    }
                    catch Exception.Error(let type, let message)
                    {
                        print("HtmlHandle --> parsing, error: [\(type) : \(message)]");
                    }
                    catch
                    {
                        print("HtmlHandle --> parsing, error!");
                    }
                }
                
                completionHandler(webLink, webMediaLink, webMediaName, webScript);
            }
            break;
        case "news.tv-asahi.co.jp":
            /*
             *  script source: http://news.tv-asahi.co.jp/news-international/articles/000136013.html
             *  player source: https://ex-ann-w.webcdn.stream.ne.jp/www11/ex-ann-w/000136013.mp4
             * */
            webLink = "http://" + host + path;
            print("HtmlHandle --> parsing, clean link: \(webLink!)");
            /*
             *  to creat a web media link
             */
            url = URL(string: link!);
            pathSeg = url!.pathComponents.last ?? "" ;   // getLastPathSegment();
            if pathSeg != "" && pathSeg!.contains(".html")
            {
                pathSeg = pathSeg!.replacingOccurrences(of: ".html", with: ".mp4")
            }
            webMediaLink = "https://ex-ann-w.webcdn.stream.ne.jp/www11/ex-ann-w/" + pathSeg!;
            print("HtmlHandle --> parsing, web media link: \(webMediaLink!)");
            webMediaName = convertURL(webMediaLink);
            print("HtmlHandle --> parsing, web media name: \(webMediaName ?? "")");
            /*
             *  to creat a web script
             */
            connectURL(webLink!) { (rawContent, errorMessage) in
                
                if let rawContent: String = rawContent
                {
                    do
                    {
                        document = try SwiftSoup.parse(rawContent);
                        /*LOCATE MEDIA*/
                        //                    element = document.selectFirst("#videoplayer > source:nth-child(1)");
                        //                    text = element.html();
                        //                    Log.v("HTML_PARSER", "media: " + text);
                        /*LOCATE SCRIPTS*/
                        element = try document!.select("#news_body").first();
                        //element = document.selectFirst("#contents-wrap > div.con > div.wrap-container > div > section.second-box > div.maintext");
                        let content = try element!.html();
                        webScript = content.replacingOccurrences(of: "<br>", with: " ");
                        print("HtmlHandle --> pasring, script: \(webScript!)");
                    }
                    catch Exception.Error(let type, let message)
                    {
                        print("HtmlHandle --> parsing, error: [\(type) : \(message)]");
                    }
                    catch
                    {
                        print("HtmlHandle --> parsing, error!");
                    }
                }
                
                completionHandler(webLink, webMediaLink, webMediaName, webScript);
            }
            break;
        case "www3.nhk.or.jp":
            webLink = link;
            print("HtmlHandle --> parsing, clean link: \(webLink!)");
            /*
             *  to creat a web media link
             */
            webMediaLink = nil;
            print("HtmlHandle --> parsing, web media link: \(webMediaLink ?? "")");
            webMediaName = convertURL(webMediaLink);
            print("HtmlHandle --> parsing, web media name: \(webMediaName ?? "")");
            /*
             *  to creat a web script
             */
            connectURL(webLink!) { (rawContent, errorMessage) in
                
                //print("HtmlHandle --> parsing, content: \(content)");
                
                if let rawContent: String = rawContent
                {
                    do
                    {
                        document = try SwiftSoup.parse(rawContent);
                        //                        selector = document.body().html();
                        //                        Log.v("HTML_PARSER", "selector: " + selector);
                        /*LOCATE MEDIA*/
                        //                    element = document.selectFirst("#video_html5player");
                        //                    text = element.html();
                        //                    Log.v("HTML_PARSER", "media: " + text);
                        /*LOCATE SCRIPTS*/
                        element = try document!.body()!.select("#news_textbody").first();
                        let temp1 = try element!.html() + "\n\r";
                        element = try document!.body()!.select("#news_textmore").first();
                        let temp2 = try element!.html();
                        let content = temp1 + temp2;
                        webScript = content.replacingOccurrences(of: "<br>", with: " ");
                        print("HtmlHandle --> parsing, script: \(webScript!)");
                    }
                    catch Exception.Error(let type, let message)
                    {
                        print("HtmlHandle --> parsing, error: [\(type) : \(message)]");
                    }
                    catch
                    {
                        print("HtmlHandle --> parsing, error!");
                    }
                }
                
                completionHandler(webLink, webMediaLink, webMediaName, webScript);
            }
            break;
        case "www9.nhk.or.jp":
            webLink = link;
            print("HtmlHandle --> parsing, clean link: \(webLink!)");
            webMediaLink = link;
            print("HtmlHandle --> parsing, web media link: \(webMediaLink ?? "")");
            webMediaName = convertURL(webMediaLink);
            print("HtmlHandle --> parsing, web media name: \(webMediaName ?? "")");
            webScript = "No Content Provided…";
            print("HtmlHandle --> parsing, script: \(webScript!)");
            completionHandler(webLink, webMediaLink, webMediaName, webScript)
            break;
        default:
            webLink = link;
            print("HtmlHandle --> parsing, clean link: \(webLink!)");
            webMediaLink = nil;
            print("HtmlHandle --> parsing, web media link: \(webMediaLink ?? "")");
            webMediaName = convertURL(webMediaLink);
            print("HtmlHandle --> parsing, web media name: \(webMediaName ?? "")");
            webScript = "No Yet Supported…";
            print("HtmlHandle --> parsing, script: \(webScript!)");
            completionHandler(webLink, webMediaLink, webMediaName, webScript);
            break;
        }
    }
    
    private func convertURL(_ source: String?) -> String?
    {
        if(source == nil)
        {
            print("HtmlHandle --> URL, empty input");
            
            return nil;
        }
        
        guard let url = URL(string: source!) else
        {
            print("HtmlHandle --> URL, invalid");
            
            return nil;
        }
        
        let lastPathSeg = url.lastPathComponent;
        
        print("HtmlHandle --> URL, last path component: \(lastPathSeg)");
        
        if lastPathSeg.hasSuffix(".mp3") || lastPathSeg.hasSuffix(".mp4")
        {
            return lastPathSeg;
        }
        else
        {
            return nil;
        }
    }
    
    private func connectURL(_ source: String, completionHandler: @escaping (_ rawContent: String?, _ errorMessage: String?) -> Void )
    {
        /*
         *  https://github.com/scinfu/SwiftSoup/issues/28
         *  https://fluffy.es/nsurlsession-urlsession-tutorial/
         */
        
        let url = URL(string: source)!
        
        var content: String?;
        
        let config = URLSessionConfiguration.default;
        
        config.httpAdditionalHeaders = ["User-Agent" : Agent];
        
        print ("HtmlHandle --> connection, User Agent: \(Agent)");
        
        config.timeoutIntervalForRequest = 10;  //for only 10 seconds.
        
        _session = URLSession(configuration: config);
        
        print ("HtmlHandle --> connection, making a session");
        
        _dataTask = _session!.dataTask(with: url) { data, response, error in
            
            // ensure there is no error for this HTTP response
            if error != nil
            {
                let message = error!.localizedDescription;
                
                print ("HtmlHandle --> connection, error: \(message)");
                
                completionHandler(nil, message);
                
                return;
            }
            
            // ensure there is good response from this HTTP response
            if let response = response as? HTTPURLResponse
            {
                let code = response.statusCode;
                
                if code != 200
                {
                    let message = HTTPURLResponse.localizedString(forStatusCode: code);
                    
                    print ("HtmlHandle --> connection, response: \(message)");
                    
                    completionHandler(nil, message);
                    
                    return;
                }
            }
            
            // ensure there is data returned from this HTTP response
            if let rawContent = data
            {
                content = String(data: rawContent, encoding: .utf8)!;
                
                //print ("HtmlHandle --> connection, content got: \(text)");
                
                completionHandler(content, nil);
                
                return;
            }
        }
        
        print ("HtmlHandle --> connection, starting a session task");
        
        _dataTask!.resume();  // execute the HTTP request
    }
}
