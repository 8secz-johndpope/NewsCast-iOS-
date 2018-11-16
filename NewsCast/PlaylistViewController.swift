//
//  PlaylistViewController.swift
//  MyApp
//
//  Created by Jose Adams on 2018/10/11.
//  Copyright © 2018 Jose Adams. All rights reserved.
//

import UIKit

class PlaylistViewController: UIViewController {

    /*UI LOGIC*/
    var isFavouriteDesc: Bool = false;
    var isDownloadsDesc: Bool = false;
    var isFavouriteTVShow: Bool = false;
    var isDownloadsTVShow: Bool = false;
    var buttonTitleFocusColor = UIColor(displayP3Red: 0.70, green: 0.0, blue: 0.0, alpha: 1.0)
    var buttonTitleIgnoreColor = UIColor(white: CGFloat(1.0), alpha: CGFloat(1.0));
    var buttonBackgroundFocusColor = UIColor(white: CGFloat(1.0), alpha: CGFloat(1.0));
    var buttonBackgroundIgnoreColor = UIColor(displayP3Red: 0.70, green: 0.0, blue: 0.0, alpha: 1.0);
    
    /*DATA*/
    var listDataFromDAO: RssData?;
    var listArrayFromDAO: [RssData]?;
    
    /*HANDLE*/
    var dao: DaoHandle?;
    
    /*Delegate*/
    var listArrayTV: ListArrayTableViewAdapter?;
    
    /*NotificationCenter*/
    let notice = NotificationCenter.default;
    var observer: NSObjectProtocol?
    
    /* File Management */
    let File = FileManager.default;
    
    /*DispatchQueue*/
    let queue = DispatchQueue.main;
    
    /*Timer*/
    var timer: Timer?;
    
    /*View Controller Manager*/
    let vcBridge = ViewControllerManager.Bridge;
    
    /* Storyboard */
    
    @IBOutlet weak var myTitleBar: UIView!
    @IBOutlet weak var mySort: UIButton!
    @IBOutlet weak var myReload: UIButton!
    @IBOutlet weak var myDownload: UIButton!
    @IBOutlet weak var myFavourite: UIButton!
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet var myIndicator: UIActivityIndicatorView!
    @IBOutlet var myLabel: UILabel!
    
    @IBAction func mySort(_ sender: UIButton)
    {
        initSorting();
    }
    
    @IBAction func myReload(_ sender: UIButton)
    {
        myReload.isEnabled = false;
        
        let vc = vcBridge.ReloadVC;
        
        vc.modalTransitionStyle = UIModalTransitionStyle.crossDissolve;
        
        self.present(vc, animated: true, completion: nil);
    }
    
    @IBAction func myFavourite(_ sender: UIButton)
    {
        print("PlaylistVC --> to show favourite list");
        
        if isDownloadsTVShow
        {
            isFavouriteTVShow = true;
            isDownloadsTVShow = false;
        
            initLoading();
        }
    }
    
    @IBAction func myDownload(_ sender: UIButton)
    {
        print("PlaylistVC --> to show download list");
        
        if isFavouriteTVShow
        {
            isFavouriteTVShow = false;
            isDownloadsTVShow = true;
        
            initLoading();
        }
    }
    
    /* Life Cycle */
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("PlaylistViewController, viewDidLoad");
        
        // Do any additional setup after loading the view.
        
        myFavourite.isEnabled = true;
        myDownload.isEnabled = true;
        
        isFavouriteTVShow = true;
        isDownloadsTVShow = false;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        print("PlaylistViewController, viewWillAppear");
        
        initView();
        addObserver();
        initLoading();
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        print("PlaylistViewController, viewDidAppear");
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        print("PlaylistViewController, viewWillDisappear");
        
        delObserver();
        
        dao = nil;
        
        showMyIndicator(false);
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        print("PlaylistViewController, viewDidDisappear");
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func initView()
    {
        myReload.isEnabled = true;
        mySort.isEnabled = false;
        
        showMyTable(nil);
        
        showMyLabel(false);
        
        showMyIndicator(true);
        
    }
    
    func addObserver()
    {
        print("PlaylistVC --> adding observer");
        
        observer = notice.addObserver(forName: Notification.Name(rawValue: "PlaylistVC"), object: nil, queue: OperationQueue.main) { (notification) in
            
            let userInfo = notification.userInfo as! [String : Any];
            
            print("PlaylistVC --> userInfo: \(userInfo)");
            
            if self.isFavouriteTVShow
            {
                if let message = userInfo["DaoHandle"] as! String?
                {
                    self.showMyIndicator(false);
                    
                    switch(message)
                    {
                    case "FETCHED":
                        // retrieve data array
                        self.listArrayFromDAO = self.dao!.RssDataArray;
                        // creating the delegate object and passing the data
                        self.listArrayTV = nil;
                        self.listArrayTV = ListArrayTableViewAdapter(self.listArrayFromDAO!)
                        // passing a function to the delegate object
                        self.listArrayTV!.DidSelectRow = self.listArrayTableDidSelect;
                        self.listArrayTV!.WillDeleteRow = self.listArrayTableWillDelete;
                        self.listArrayTV!.DidDeleteRow = self.listArrayTableDidDelete;
                        // setting the delegate object to tableView
                        self.showMyTable(self.listArrayTV);
                        self.showMyLabel(false);
                        self.mySort.isEnabled = true;
                        break;
                    case "EMPTY":
                        self.showMyTable(nil);
                        self.showMyLabel(true);
                        self.mySort.isEnabled = false;
                        break;
                    case "UPDATED":
                        self.initLoading();
                        break;
                    case "UPDATE_FAILED":
                        break;
                    default:
                        break;
                    }
                }
            }
            else if self.isDownloadsTVShow
            {
                if let message = userInfo["DaoHandle"] as! String?
                {
                    self.showMyIndicator(false);
                    
                    switch(message)
                    {
                    case "FETCHED":
                        // retrieve data array
                        self.listArrayFromDAO = self.dao!.RssDataArray;
                        // creating the delegate object and passing the data
                        self.listArrayTV = nil;
                        self.listArrayTV = ListArrayTableViewAdapter(self.listArrayFromDAO!)
                        // passing a function to the delegate object
                        self.listArrayTV!.DidSelectRow = self.listArrayTableDidSelect;
                        self.listArrayTV!.WillDeleteRow = self.listArrayTableWillDelete;
                        self.listArrayTV!.DidDeleteRow = self.listArrayTableDidDelete;
                        // setting the delegate object to tableView
                        self.showMyTable(self.listArrayTV);
                        self.showMyLabel(false);
                        self.mySort.isEnabled = true;
                        break;
                    case "EMPTY":
                        self.showMyTable(nil);
                        self.showMyLabel(true);
                        self.mySort.isEnabled = false;
                        break;
                    case "UPDATED":
                        self.initLoading();
                        break;
                    case "UPDATE_FAILED":
                        break;
                    default:
                        break;
                    }
                }
            }
        }
    }
    
    func delObserver()
    {
        print("PlaylistVC --> removing observer");
        
        if observer != nil
        {
            notice.removeObserver(observer!);
        }
    }
    
    func showMyTable(_ object: NSObject?)
    {
        if object != nil
        {
            myTableView.isHidden = false;
            myTableView.delegate = (object! as! UITableViewDelegate);
            myTableView.dataSource = (object! as! UITableViewDataSource);
            myTableView.reloadData();
        }
        else
        {
            self.myTableView.isHidden = true;
        }
    }
    
    func showMyLabel(_ show: Bool)
    {
        if show
        {
            myLabel.isHidden = false;
        }
        else
        {
            myLabel.isHidden = true;
        }
    }
    
    func showMyIndicator(_ show: Bool)
    {
        if show
        {
            myIndicator.isHidden = false;
        }
        else
        {
            myIndicator.isHidden = true;
        }
    }
    
    func initLoading()
    {
        showMyIndicator(true);
        
        mySort.isEnabled = false;
        
        myTableView.isHidden = true;
        
        if isFavouriteTVShow
        {
            print("PlaylistVC --> preparing for Favourite List...");
            
            myFavourite.setTitleColor(buttonTitleFocusColor, for: UIControl.State.normal);
            myDownload.setTitleColor(buttonTitleIgnoreColor, for: UIControl.State.normal);
            
            myFavourite.backgroundColor = buttonBackgroundFocusColor;
            myDownload.backgroundColor = buttonBackgroundIgnoreColor;
            
            isFavouriteDesc = true;

            dao = nil;
            dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "PlaylistVC");
            dao!.fetchDataArray(Column: DaoHandle.MARK, Like: DaoHandle.SET, Order: DaoHandle.DATE, Sort: DaoHandle.DESC);
        }
        else if isDownloadsTVShow
        {
            print("PlaylistVC --> preparing for Download List...");
            
            myFavourite.setTitleColor(buttonTitleIgnoreColor, for: UIControl.State.normal);
            myDownload.setTitleColor(buttonTitleFocusColor, for: UIControl.State.normal);
            
            myFavourite.backgroundColor = buttonBackgroundIgnoreColor;
            myDownload.backgroundColor = buttonBackgroundFocusColor;
            
            isDownloadsDesc = true;
            
            dao = nil;
            dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "PlaylistVC");
            dao!.fetchDataArrayMedia(Column: nil, Like: nil, Order: DaoHandle.DATE, Sort: DaoHandle.DESC);
        }
    }
    
    func initSorting()
    {
        showMyIndicator(true);
        
        mySort.isEnabled = false;
        
        myTableView.isHidden = true;
        
        if isFavouriteTVShow
        {
            if !isFavouriteDesc
            {
                isFavouriteDesc = true;
                
                dao = nil;
                dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "PlaylistVC");
                dao!.fetchDataArray(Column: DaoHandle.MARK, Like: DaoHandle.SET, Order: DaoHandle.DATE, Sort: DaoHandle.DESC);
            }
            else
            {
                isFavouriteDesc = false;
                
                dao = nil;
                dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "PlaylistVC");
                dao!.fetchDataArray(Column: DaoHandle.MARK, Like: DaoHandle.SET, Order: DaoHandle.DATE, Sort: DaoHandle.ASC);
            }
        }
        else if isDownloadsTVShow
        {
            if !isDownloadsDesc
            {
                isDownloadsDesc = true;
                
                dao = nil;
                dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "PlaylistVC");
                dao!.fetchDataArrayMedia(Column: nil, Like: nil, Order: DaoHandle.DATE, Sort: DaoHandle.DESC);
            }
            else
            {
                isDownloadsDesc = false;
                
                dao = nil;
                dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "PlaylistVC");
                dao!.fetchDataArrayMedia(Column: nil, Like: nil, Order: DaoHandle.DATE, Sort: DaoHandle.ASC);
            }
        }
    }
    
    func listArrayTableDidSelect(_ data: RssData)
    {
        print("PlaylistVC --> ListArrayTV did select:  \(data.Title!)")
        
        vcBridge.Data = data;
        
        let vc = vcBridge.PlayerVC;
        
        vc.modalTransitionStyle = UIModalTransitionStyle.crossDissolve;
        
        self.present(vc, animated: true, completion: nil);
    }
    
    func listArrayTableWillDelete(_ data: RssData)
    {
        print("PlaylistVC --> ListArrayTV, will delete:  \(data.Title!)");
        
    }
    
    func listArrayTableDidDelete(_ data: RssData)
    {
        print("PlaylistVC --> ListArrayTV, did delete:  \(data.Title!)");
        
        let alert = UIAlertController(title: "...Deleting...", message: "\(data.Title!)", preferredStyle: UIAlertController.Style.alert);
        
        let actionYes = UIAlertAction(title: "YES", style: UIAlertAction.Style.default) { (action) in
            
            if self.isFavouriteTVShow
            {
                data.Mark = DaoHandle.UNSET;
                
                self.myTableView.isHidden = true;
                
                self.showMyIndicator(true);
                
                self.dao = nil
                self.dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "PlaylistVC");
                self.dao!.updateData(data);
            }
            else if self.isDownloadsTVShow
            {
                let targetPath = "\(NSHomeDirectory())/Documents/\(data.Media!)";
                
                if self.File.fileExists(atPath: targetPath)
                {
                    try? self.File.removeItem(atPath: targetPath);
                }
                
                data.Media = nil;
                
                self.myTableView.isHidden = true;
                
                self.showMyIndicator(true);
                
                self.dao = nil;
                self.dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "PlaylistVC");
                self.dao!.updateData(data);
            }
        }
        
        let actionNo = UIAlertAction(title: "No", style: UIAlertAction.Style.default, handler: nil)
        
        alert.addAction(actionYes);
        alert.addAction(actionNo);
        
        self.present(alert, animated: true, completion: nil);
        
    }
    
}
