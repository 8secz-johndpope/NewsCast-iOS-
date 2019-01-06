//
//  DownloadHandle.swift
//  NewsCast
//
//  Created by Jose Adams on 2018/10/29.
//  Copyright © 2018 Jose Adams. All rights reserved.
//

import UIKit

class DownloadHandle: NSObject, URLSessionDownloadDelegate
{
    
    /*ATTRIBUTES*/
    
    private var _fileLink: String?;
    private var _fileName: String?;
    private var _session: URLSession?;
    private var _downloadTask: URLSessionDownloadTask?;
    private var _response = "";
    private let Notice = NotificationCenter.default;
    private let Queue = DispatchQueue.main;
    private let File = FileManager.default;
    private let Agent = "Mozilla/5.0 (Android 8.0.0; Mobile; rv:62.0) Gecko/62.0 Firefox/62.0";
    
    /* CONSTRUCTOR */
    
    init(FileLink link: String, FileName name: String, Response response: String)
    {
        _fileLink = link;
        _fileName = name;
        _response = response;
    }
    
    /* GETTER / SETTER */
    
    var FileLink: String?
    {
        get
        {
            return _fileLink;
        }
        set
        {
            _fileLink = newValue;
        }
    }
    
    var FileName: String?
    {
        get
        {
            return _fileName;
        }
        set
        {
            _fileName = newValue
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
            _response = newValue
        }
    }
    
    /* methods */
    
    private func throwMessage(_ message: String)
    {
        Notice.post(name:Notification.Name(rawValue: _response), object: nil, userInfo: ["Download_Message":message]);
    }
    
    private func throwProgress(_ progress: Float)
    {
        Notice.post(name:Notification.Name(rawValue: _response), object: nil, userInfo: ["Download_Progress":progress]);
    }
    
    func proceed()
    {
        let url = URL(string: _fileLink!)
        
        let config = URLSessionConfiguration.default;
        
        config.httpAdditionalHeaders = ["User-Agent" : Agent];
        
        print ("DownloadHandle --> connection, User Agent: \(Agent)");
        
        config.timeoutIntervalForRequest = 10;  //for only 10 seconds.
        
        _session = URLSession(configuration: config, delegate: self, delegateQueue: .main);
        
        print ("DownloadHandle --> connection, making a session");
        
        _downloadTask = _session!.downloadTask(with: url!);
        
        print ("DownloadHandle --> connection, starting a download task");
        
        _downloadTask!.resume();  // execute the HTTP request
    }
    
    func cancel()
    {
        if _downloadTask == nil
        {
            print ("DownloadHandle --> URL Session Download Task is empty");
        }
        else
        {
            _downloadTask!.cancel();
            
            _downloadTask = nil;
        }
        
        if _session == nil
        {
            print ("DownloadHandle --> URL Session is empty");
        }
        else
        {
            _session!.invalidateAndCancel();
            
            _session = nil;
        }
    }
    
    
    /* delegattion */
    
    /*
     *  https://developer.apple.com/documentation/foundation/urlsessiondownloaddelegate
     */
    
    // Handling Download Life Cycle Changes
    
    internal func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        print("DownloadHandle --> session finished");
        
        let targetFileURL = URL(fileURLWithPath: "\(NSHomeDirectory())/Documents/\(_fileName!)" )   /// <-- the running environment
        
        print("DownloadHandle --> offline file path: \(targetFileURL)");
        
        let sourceDataURL = NSData(contentsOf: location)
        
        print("DownloadHandle --> writing file to preset location");
        
        if sourceDataURL!.write(to: targetFileURL, atomically: true)
        {
            print("DownloadHandle --> writing file successful!...");
            
            self.throwMessage("DOWNLOADED_AND_SAVED");
        }
        else
        {
            print("DownloadHandle --> writing file failed...");
            
            self.throwMessage("DOWNLOADED_BUT_SAVE_FAILED");
        }
    }
   
    // Handling Task Life Cycle Changes
    
    internal func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if error != nil
        {
            print ("DownloadHandle --> downloding error: \(error!.localizedDescription)");
            
            task.cancel();
            
            session.invalidateAndCancel();
            
            throwMessage("DOWNLOAD_FAILED");
            
            return;
        }
    }
    
    // Receiving Progress Updates
    
    internal func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        if totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown
        {
            print("DownloadHandle --> File Total Length: UnKnown");
        }
        else
        {
            let expected = Double(totalBytesExpectedToWrite);
            let written = Double(totalBytesWritten);
            let progress = Float( written / expected );
            
            print("DownloadHandle --> file length to be expected: \(expected)");
            print("DownloadHandle --> file length to be written: \(written)");
            
            throwProgress(progress);
        }
    }
}
