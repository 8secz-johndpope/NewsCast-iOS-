//
//  WelcomeViewController.swift
//  MyApp
//
//  Created by Jose Adams on 2018/10/18.
//  Copyright © 2018 Jose Adams. All rights reserved.
//

import UIKit

class ReloadViewController: UIViewController {

    /* UI logic*/
    var imageArray: [UIImage]?;
    var imageIndex: Int = 0;
    
    /*DATA*/
    var headDataFromDAO: RssData?;
    var headDataFromXML: RssData?;
    var dataArrayFromXML: [RssData]?;
    var dataArrayFromDAO: [RssData]?;
    var indexOfDataArrayFromDAO: Int = 0;
    var sizeOfDataArrayFromDAO: Int = 0;
    
    /*HANDLE*/
    var xml: XmlHandle?;
    var dao: DaoHandle?;
    
    /*NotificationCenter*/
    let notice = NotificationCenter.default;
    var observer: NSObjectProtocol?
    
    /* Storyboard */
    
    @IBOutlet weak var mySplash: UIImageView!
    @IBOutlet weak var myMessage: UILabel!
    
    /* Life Cycle*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("ReloadViewController, viewDidLoad");
        
        // Do any additional setup after loading the view.
        
        imageArray = createImageArray(4, "splash");
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        print("ReloadViewController, viewWillAppear");
        
        startAnimation(mySplash, imageArray!);
        
        addObserver();
        initLoading();
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        print("ReloadViewController, viewDidAppear");
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        print("ReloadViewController, viewWillDisappear");
        
        /*
         *  https://oleb.net/blog/2018/01/notificationcenter-removeobserver/
         */
        
        delObserver();
        
        dao = nil;
        
        if xml != nil
        {
            xml!.cancel();
            
            xml = nil;
        }
        
        stopAnimation(mySplash);
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        print("ReloadViewController, viewDidDisappear");
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    func addObserver()
    {
        print("ReloadVC --> adding observer");
        
        observer = notice.addObserver(forName: Notification.Name(rawValue: "ReloadVC"), object: nil, queue: OperationQueue.main) { (notification) in
            
            let userInfo = notification.userInfo as! [String : Any];
            
            print("ReloadVC --> \(userInfo)");
            
            if let message = userInfo["DaoHandle"] as! String?
            {
                switch(message)
                {
                case "FETCHED":
                    self.dataArrayFromDAO = self.dao!.RssDataArray;
                    self.sizeOfDataArrayFromDAO = self.dataArrayFromDAO!.count
                    print("ReloadVC --> RssDataArray's Size: \(self.sizeOfDataArrayFromDAO )");
                    
                    self.indexOfDataArrayFromDAO = 0;
                
                    self.headDataFromDAO = self.dataArrayFromDAO![self.indexOfDataArrayFromDAO];
                    self.indexOfDataArrayFromDAO += 1;
                    let link: String = self.headDataFromDAO!.Link ?? "";
                    print("ReloadVC --> HeadData's Link: \(link)");
                
                    self.myMessage.text = "...XML Fetching...";
                    
                    self.xml = nil;
                    self.xml = XmlHandle(Url: link, Response: "ReloadVC");
                    self.xml!.proceed();
                    
                    break;
                case "EMPTY":   /// nothing in DATABASE, a whole new start...
                    self.cleanUpItemDataOlderThan(30);
                    break;
                case "UPDATED": /// SINGLE, for head data
                    
                    self.myMessage.text = "...DAO Inserting...";
                    
                    self.dao = nil;
                    self.dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "ReloadVC" );
                    self.dao!.batchInsertDataWithUpdate(self.dataArrayFromXML!);
                    break;
                case "BATCH_INSERTED":  //MULTIPLE, item data
                    if self.indexOfDataArrayFromDAO >= self.sizeOfDataArrayFromDAO
                    {
                        self.cleanUpItemDataOlderThan(30);
                    }
                    else
                    {
                        self.nextHeadDataFromDaoToGo();
                    }
                    break;
                case "CLEANED_UP":
                    self.returnToPrevViewController();
                    break;
                default:
                    break;
                }
            }
            else if let message = userInfo["XmlHandle"] as! String?
            {
                switch(message)
                {
                case "FETCHED":
                    let value = self.xml!.hashValue;
                    print("ReloadVC --> XmlHandle's HashValue, after : \(value)");
                    
                    self.dataArrayFromXML = self.xml!.RssDataArray;
                    self.headDataFromXML = self.dataArrayFromXML!.remove(at: 0);
                    print("ReloadVC --> HeadDataFromXml's parent: \(self.headDataFromXML!.Parent!)");
                
                    let pubdateFromXML = self.headDataFromXML!.PubDate!;
                    let pubdateFromDAO = self.headDataFromDAO!.PubDate ?? nil;
                
                    if(pubdateFromDAO == nil ||  pubdateFromDAO != pubdateFromXML)  //pubdate isn't coherent
                    {
                        self.headDataFromDAO!.PubDate = pubdateFromXML; //update the pubdate
                        print("ReloadVC --> updating HeadData's PubDate");
                        
                        self.myMessage.text = "...DAO Updating...";
                        
                        self.dao = nil;
                        self.dao = DaoHandle.init(Table: DaoHandle.FEEDLIST, Response: "ReloadVC");
                        self.dao!.updateData(self.headDataFromDAO!);
                    }
                    else
                    {
                        if self.indexOfDataArrayFromDAO >= self.sizeOfDataArrayFromDAO
                        {
                            self.cleanUpItemDataOlderThan(30);
                        }
                        else
                        {
                            self.nextHeadDataFromDaoToGo();
                        }
                    }
                    break;
                case "EMPTY", "FAILED":
                    if self.indexOfDataArrayFromDAO >= self.sizeOfDataArrayFromDAO
                    {
                        self.cleanUpItemDataOlderThan(30);
                    }
                    else
                    {
                        self.nextHeadDataFromDaoToGo();
                    }
                    break;
                default:
                    break;
                }
            }
        }
    }
    
    func delObserver()
    {
        print("ReloadVC --> removing observer");
        
        if observer != nil
        {
            notice.removeObserver(observer!);
        }
    }
    
    func initLoading()
    {
        print("ReloadVC --> start a new process");
        
        self.myMessage.text = "...DAO Fetching...";
        
        dao = nil;
        dao = DaoHandle.init(Table: DaoHandle.FEEDLIST, Response: "ReloadVC")
        dao!.fetchDataArray();
    }
    
    func nextHeadDataFromDaoToGo()
    {
        headDataFromDAO = dataArrayFromDAO![indexOfDataArrayFromDAO];
        indexOfDataArrayFromDAO += 1;
        
        let link: String = headDataFromDAO!.Link!;    //where the source of rss
        print("ReloadVC --> headDataFromDAO, link: \(link)");
        
        self.myMessage.text = "...XML Fetching...";
        
        xml = nil;
        xml = XmlHandle.init(Url: link, Response: "ReloadVC");
        xml!.proceed();
    }
    
    func cleanUpItemDataOlderThan(_ days: Int)
    {
        print("ReloadVC --> starting to clean up old items")
        
        let cal = Calendar.current;
        let format = DateFormatter();
        format.locale = Locale.current;
        format.dateFormat = "yyyy-MM-dd HH:mm:ss";
        
        var date = Date();
        
        let today = format.string(from: date);
        print("ReloadVC --> today: \(today)");
        
        date = cal.date(byAdding: .day, value: -days, to: date)!
        
        let pastday = format.string(from: date);
        print("ReloadVC --> pastday: \(pastday)");
        
        self.myMessage.text = "...DAO Cleaning...";
        
        dao = nil;
        dao = DaoHandle.init(Table: DaoHandle.ITEMLIST, Response: "ReloadVC");
        dao!.deleteItemDataWithDefaultExceptionAndOlderThan(pastday)
    }
    
    func returnToPrevViewController()
    {
        print("ReloadVC --> go to preset view controller")
        
        self.myMessage.text = "...Ready...";
        
        dismiss(animated: true, completion: nil);
    }
    
    func createImageArray(_ total: Int, _ prefix: String) -> [UIImage]
    {
        var array = [UIImage]();
        for index in 0..<total
        {
            let name = "\(prefix)_\(index).png";
            let element = UIImage(named: name)!;
            array.append(element);
        }
        
        return array;
    }
    
    func startAnimation(_ imageView: UIImageView, _ images: [UIImage])
    {
        imageView.animationImages = images;
        imageView.animationRepeatCount = 0; //always
        imageView.animationDuration = 0.50;
        imageView.startAnimating();
    }
    
    func stopAnimation(_ imageView: UIImageView)
    {
        imageView.stopAnimating();
    }
}
