//
//  WelcomeViewController.swift
//  NewsCast
//
//  Created by Jose Adams on 2018/10/26.
//  Copyright © 2018 Jose Adams. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {

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
    
    @IBOutlet weak var myGlobe: UIImageView!
    @IBOutlet weak var myMessage: UILabel!
    
    /* Life Cycle */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("WelcomeViewController, viewDidLoad");
        
        // Do any additional setup after loading the view.
        
        /*
         *  https://stackoverflow.com/questions/45694538/ios-swift-add-svg-image-to-button-like-android
         *  https://github.com/mchoe/SwiftSVG
         *  https://cocoapods.org/pods/SwiftSVG
         *  https://www.youtube.com/watch?v=oe8kJYLR-qQ
         */
        
        imageArray = createImageArray(4, "globe");
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        print("WelcomeViewController, viewWillAppear");
        
        startAnimation(myGlobe, imageArray!);
        
        addObserver();
        initLoading();
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        print("WelcomeViewController, viewDidAppear");
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        print("WelcomeViewController, viewWillDisappear");
        
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
        
        stopAnimation(myGlobe);
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        print("WelcomeViewController, viewDidDisappear");
        
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
        print("WelcomeVC --> adding observer");
        
        observer = notice.addObserver(forName: Notification.Name(rawValue: "WelcomeVC"), object: nil, queue: OperationQueue.main) { (notification) in
            
            let userInfo = notification.userInfo as! [String : Any];
            
            print("WelcomeVC --> \(userInfo)");
            
            if let message = userInfo["DaoHandle"] as! String?
            {
                switch(message)
                {
                case "FETCHED":
                    self.dataArrayFromDAO = self.dao!.RssDataArray;
                    self.sizeOfDataArrayFromDAO = self.dataArrayFromDAO!.count
                    print("WelcomeVC --> RssDataArray's Size: \(self.sizeOfDataArrayFromDAO )");
                    
                    self.indexOfDataArrayFromDAO = 0;
                    
                    self.headDataFromDAO = self.dataArrayFromDAO![self.indexOfDataArrayFromDAO];
                    self.indexOfDataArrayFromDAO += 1;
                    let link: String = self.headDataFromDAO!.Link ?? "";
                    print("WelcomeVC --> HeadData's Link: \(link)");
                    
                    self.myMessage.text = "...XML Fetching...";
                    
                    self.xml = nil;
                    self.xml = XmlHandle(Url: link, Response: "WelcomeVC");
                    self.xml!.proceed();
                    
                    break;
                case "EMPTY":   /// nothing in DATABASE, a whole new start...
                    self.cleanUpItemDataOlderThan(30);
                    break;
                case "UPDATED": /// SINGLE, for head data
                    
                    self.myMessage.text = "...DAO Inserting...";
                    
                    self.dao = nil;
                    self.dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "WelcomeVC" );
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
                    self.BoundForNextViewController();
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
                    self.dataArrayFromXML = self.xml!.RssDataArray;
                    self.headDataFromXML = self.dataArrayFromXML!.remove(at: 0);
                    print("WelcomeVC --> HeadDataFromXml's parent: \(self.headDataFromXML!.Parent!)");
                    
                    let pubdateFromXML = self.headDataFromXML!.PubDate!;
                    let pubdateFromDAO = self.headDataFromDAO!.PubDate ?? nil;
                    
                    let titleFromXML = self.headDataFromXML!.Title!;
                    
                    if(pubdateFromDAO == nil ||  pubdateFromDAO != pubdateFromXML)  //pubdate isn't coherent
                    {
                        self.headDataFromDAO!.PubDate = pubdateFromXML; //update the pubdate
                        print("WelcomeVC --> updating HeadData's PubDate");
                        
                        self.headDataFromDAO!.Title = titleFromXML;
                        print("WelcomeVC --> updating HeadData's Title");
                        
                        self.myMessage.text = "...DAO Updating...";
                        
                        self.dao = nil;
                        self.dao = DaoHandle.init(Table: DaoHandle.FEEDLIST, Response: "WelcomeVC");
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
        print("WelcomeVC --> removing observer");
        
        if observer != nil
        {
            notice.removeObserver(observer!);
        }
        
    }
    
    func initLoading()
    {
        print("WelcomeVC --> start a new process");
        
        self.myMessage.text = "...DAO Fetching...";
        
        dao = nil;
        dao = DaoHandle.init(Table: DaoHandle.FEEDLIST, Response: "WelcomeVC")
        dao!.fetchDataArray();
    }
    
    func nextHeadDataFromDaoToGo()
    {
        headDataFromDAO = dataArrayFromDAO![indexOfDataArrayFromDAO];
        indexOfDataArrayFromDAO += 1;
        
        let link: String = headDataFromDAO!.Link!;    //where the source of rss
        print("WelcomeVC --> headDataFromDAO, link: \(link)");
        
        self.myMessage.text = "...XML Fetching...";
        
        xml = nil;
        xml = XmlHandle.init(Url: link, Response: "WelcomeVC");
        xml!.proceed();
    }
    
    func cleanUpItemDataOlderThan(_ days: Int)
    {
        print("WelcomeVC --> starting to clean up old items")
        
        let cal = Calendar.current;
        let format = DateFormatter();
        format.locale = Locale.current;
        format.dateFormat = "yyyy-MM-dd HH:mm:ss";
        
        var date = Date();
        
        let today = format.string(from: date);
        print("WelcomeVC --> today: \(today)");
        
        date = cal.date(byAdding: .day, value: -days, to: date)!
        
        let pastday = format.string(from: date);
        print("WelcomeVC --> pastday: \(pastday)");
        
        self.myMessage.text = "...DAO Cleaning...";
        
        dao = nil;
        dao = DaoHandle.init(Table: DaoHandle.ITEMLIST, Response: "WelcomeVC");
        dao!.deleteItemDataWithDefaultExceptionAndOlderThan(pastday)
    }
    
    func BoundForNextViewController()
    {
        print("WelcomeVC --> go to preset view controller")
        
        self.myMessage.text = "...Ready...";
        
        let vc = ViewControllerManager.Bridge.TabBarVC;
        
        vc.modalTransitionStyle = UIModalTransitionStyle.crossDissolve;
        
        self.present(vc, animated: true, completion: nil);
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
