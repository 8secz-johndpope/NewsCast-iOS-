//
//  ChannelViewController.swift
//  MyApp
//
//  Created by Jose Adams on 2018/10/9.
//  Copyright © 2018 Jose Adams. All rights reserved.
//

import UIKit

class ChannelViewController: UIViewController {

    /*UI LOGIC*/
    var isChanArrayTVShow: Bool = false;
    var isItemArrayTVShow: Bool = false;
    var isItemArrayDESC: Bool = false;
    
    /*DATA*/
    var headDataFromDAO: RssData?;
    var itemDataFromDAO: RssData?;
    var headArrayFromDAO: [RssData]?;
    var itemArrayFromDAO: [RssData]?;
    
    /*HANDLE*/
    var dao: DaoHandle?;
    
    /*Delegate*/
    var chanArrayTV: ChanArrayTableViewAdapter?;
    var itemArrayTV: ItemArrayTableViewAdapter?;
    
    /*NotificationCenter*/
    let notice = NotificationCenter.default;
    var observer: NSObjectProtocol?
    
    /*DispatchQueue*/
    let queue = DispatchQueue.main;
    
    /*Timer*/
    var timer: Timer?;
    
    /*View Controller Manager*/
    let vcBridge = ViewControllerManager.Bridge;
    
    /* Storyboard */
    
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var myDashboard: UITabBarItem!
    @IBOutlet weak var myTitle: UILabel!
    @IBOutlet weak var myReload: UIButton!
    @IBOutlet weak var mySort: UIButton!
    @IBOutlet weak var mySortWidth: NSLayoutConstraint!
    @IBOutlet weak var myEdit: UIButton!
    @IBOutlet weak var myEditWidth: NSLayoutConstraint!
    @IBOutlet weak var myBack: UIButton!
    @IBOutlet weak var myTitleBar: UIView!
    @IBOutlet weak var myTitleBarHeight: NSLayoutConstraint!
    @IBOutlet var myIndicator: UIActivityIndicatorView!
    @IBOutlet var myLabel: UILabel!
    
    @IBAction func myBack(_ sender: UIButton)
    {
        myBack.isEnabled = false;
        
        isChanArrayTVShow = true;
        isItemArrayTVShow = false;
        
        initLoading();
    }
    
    @IBAction func myReload(_ sender: UIButton)
    {
        myReload.isEnabled = false;
        
        let vc = vcBridge.ReloadVC;
        
        vc.modalTransitionStyle = UIModalTransitionStyle.crossDissolve;
        
        self.present(vc, animated: true, completion: nil);
    }
    
    @IBAction func mySort(_ sender: UIButton)
    {
        initSorting();
    }
    
    @IBAction func myEditor(_ sender: UIButton) {
        
        myEdit.isEnabled = false;
        
        let vc = vcBridge.SubscribeVC;
        
        vc.modalTransitionStyle = UIModalTransitionStyle.crossDissolve;
        
        self.present(vc, animated: true, completion: nil);
    }
    
    /* Life Cycle */
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("ChannelViewController, viewDidLoad");
        
        // Do any additional setup after loading the view.
        
        isChanArrayTVShow = true;
        isItemArrayTVShow = false;

    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        print("ChannelViewController, viewWillAppear");
        
        initView();
        addObserver();
        initLoading();
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        print("ChannelViewController, viewDidAppear");
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        print("ChannelViewController, viewWillDisappear");
        
        /*
         *  https://oleb.net/blog/2018/01/notificationcenter-removeobserver/
         */
        
        delObserver();
        
        dao = nil;
        
        showMyIndicator(false);
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        print("ChannelViewController, viewDidDisappear");
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
        
        myTitleBar.isHidden = true;
        myTitleBarHeight.constant = CGFloat(0.0);
        
        myEdit.isHidden = true;
        myEditWidth.constant = CGFloat(0.0);
        mySort.isHidden = true;
        mySortWidth.constant = CGFloat(0.0);
        
        myTableView.isHidden = true;
        
        showMyIndicator(false);
    }
    
    func addObserver()
    {
        print("ChannelVC --> adding observer");
        
        observer = notice.addObserver(forName: Notification.Name(rawValue: "ChannelVC"), object: nil, queue: OperationQueue.main) { (notification) in
            
            let userInfo = notification.userInfo as! [String : Any];
            
            print("ChannelVC --> userInfo: \(userInfo)");
            
            if self.isChanArrayTVShow
            {
                if let message = userInfo["DaoHandle"] as! String?
                {
                    self.showMyIndicator(false);
                    
                    switch(message)
                    {
                    case "FETCHED":
                        // retrieve data array
                        self.headArrayFromDAO = self.dao!.RssDataArray;
                        // creating the delegate object and passing the data
                        self.chanArrayTV = nil;
                        self.chanArrayTV = ChanArrayTableViewAdapter(self.headArrayFromDAO!);
                        // passing a function to the delegate object
                        self.chanArrayTV!.DidSelectRow = self.chanArrayTableDidSelect;
                        self.chanArrayTV!.WillDeleteRow = self.chanArrayTableWillDelete;
                        self.chanArrayTV!.DidDeleteRow = self.chanArrayTableDidDelete;
                        // setting the delegate object to tableView
                        self.showMyTable(self.chanArrayTV);
                        self.showMyLabel(false);
                        self.mySort.isEnabled = false;  // <-- always actually
                        break;
                    case "EMPTY":
                        self.showMyTable(nil);
                        self.showMyLabel(true);
                        self.mySort.isEnabled = false;
                        break;
                    case "DELETED": //where head data is deleted
                        self.showMyIndicator(true);
                        let parent = self.headDataFromDAO!.Title!;
                        self.dao = nil;
                        self.dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "ChannelVC");
                        self.dao!.deleteItemDataWithDefaultExceptionAndParentIs(parent);
                        break;
                    case "DELETE_FAILED":
                        break;
                    case "UNSUBSCRIBED":
                        self.initLoading();
                    default:
                        break;
                    }
                }
            }
            else if self.isItemArrayTVShow
            {
                if let message = userInfo["DaoHandle"] as! String?
                {
                    self.showMyIndicator(false);
                    
                    switch(message)
                    {
                    case "FETCHED":
                        // retrieve data array
                        self.itemArrayFromDAO = self.dao!.RssDataArray;
                        // creating the delegate object and passing the data
                        self.itemArrayTV = nil;
                        self.itemArrayTV = ItemArrayTableViewAdapter(self.itemArrayFromDAO!)
                        // passing a function to the delegate object
                        self.itemArrayTV!.DidSelectRow = self.itemArrayTableDidSelect;
                        self.itemArrayTV!.WillLikeRow = self.itemArrayTableWillLike;
                        self.itemArrayTV!.DidLikeRow = self.itemArrayTableDidLike;
                        self.itemArrayTV!.WillUnLikeRow = self.itemArrayTableWillUnLike;
                        self.itemArrayTV!.DidUnLikeRow = self.itemArrayTableDidUnLike;
                        // setting the delegate object to tableView
                        self.showMyTable(self.itemArrayTV);
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
        print("ChannelVC --> removing observer");
        
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
        if show == true
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
        
        if isChanArrayTVShow
        {
            myTitleBar.isHidden = true;
            myTitleBarHeight.constant = CGFloat(0.0);
            
            myEdit.isEnabled = true;
            
            myEdit.isHidden = false;
            myEditWidth.constant = CGFloat(50.0);
            
            mySort.isHidden = true;
            mySortWidth.constant = CGFloat(0.0);
            
            myTableView.isHidden = true;
            
            dao = nil;
            dao = DaoHandle(Table: DaoHandle.FEEDLIST, Response: "ChannelVC");
            dao!.fetchDataArray();
        }
        else if isItemArrayTVShow
        {
            myTitleBar.isHidden = false;
            myTitleBarHeight.constant = CGFloat(50.0);
            
            myBack.isEnabled = true;
            
            myEdit.isHidden = true;
            myEditWidth.constant = CGFloat(0.0);
            
            mySort.isHidden = false;
            mySort.isEnabled = false;
            mySortWidth.constant = CGFloat(50.0);
            
            myTableView.isHidden = true;
            
            let like: String = headDataFromDAO!.Title!;
            
            myTitle.text = like;
            
            isItemArrayDESC = true;
            
            dao = nil;
            dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "ChannelVC");
            dao!.fetchDataArray(Column: DaoHandle.PARENT, Like: like, Order: DaoHandle.DATE, Sort: DaoHandle.DESC);
        }
    }
    
    func initSorting()
    {
        if isItemArrayTVShow
        {
            mySort.isEnabled = false;
            
            showMyIndicator(true);
        
            myTitleBar.isHidden = false;
            myTitleBarHeight.constant = CGFloat(50.0);
        
            myBack.isEnabled = true;
        
            myEdit.isHidden = true;
            myEditWidth.constant = CGFloat(0.0);
        
            mySort.isHidden = false;
            mySortWidth.constant = CGFloat(50.0);
        
            myTableView.isHidden = true;
        
            let like: String = headDataFromDAO!.Title!;
        
            myTitle.text = like;
        
            dao = nil;
            dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "ChannelVC");
        
            if !isItemArrayDESC
            {
                isItemArrayDESC = true;
                dao!.fetchDataArray(Column: DaoHandle.PARENT, Like: like, Order: DaoHandle.DATE, Sort: DaoHandle.DESC);
            }
            else
            {
                isItemArrayDESC = false;
                dao!.fetchDataArray(Column: DaoHandle.PARENT, Like: like, Order: DaoHandle.DATE, Sort: DaoHandle.ASC);
            }
        }
    }
    
    func chanArrayTableDidSelect(_ data: RssData)
    {
        print("ChannelVC --> ChanArrayTV, did select:  \(data.Title!)")
        
        isChanArrayTVShow = false;
        isItemArrayTVShow = true;
        
        headDataFromDAO = data;
        
        initLoading();
    }
    
    func chanArrayTableWillDelete(_ data: RssData)
    {
        print("ChannelVC --> ChanArrayTV, will delete:  \(data.Title!)");
    }
    
    func chanArrayTableDidDelete(_ data: RssData)
    {
        print("ChannelVC --> ChanArrayTV, did delete:  \(data.Title!)");
        
        let alert = UIAlertController(title: "...Deleting...", message: "\(data.Title!)", preferredStyle: UIAlertController.Style.alert);
        
        let actionYes = UIAlertAction(title: "YES", style: UIAlertAction.Style.default) { (action) in
            
            self.myTableView.isHidden = true;
            
            self.showMyIndicator(true);
            
            self.headDataFromDAO = data;
            
            self.dao = nil;
            self.dao = DaoHandle(Table: DaoHandle.FEEDLIST, Response: "ChannelVC");
            self.dao!.deleteData(self.headDataFromDAO!);
        }
        
        let actionNo = UIAlertAction(title: "No", style: UIAlertAction.Style.default, handler: nil)
        
        alert.addAction(actionYes);
        alert.addAction(actionNo);
        
        self.present(alert, animated: true, completion: nil);
    }
    
    func itemArrayTableDidSelect(_ data: RssData)
    {
        print("ChannelVC --> ItemArrayTV did select:  \(data.Title!)")
        
        itemDataFromDAO = data;
        
        vcBridge.Data = itemDataFromDAO;
        
        let vc = vcBridge.PlayerVC;
        
        vc.modalTransitionStyle = UIModalTransitionStyle.crossDissolve;
        
        self.present(vc, animated: true, completion: nil);
    }
    
    func itemArrayTableWillLike(_ data: RssData)
    {
        print("ChannelVC --> ItemArrayTV, will like:  \(data.Title!)");
        
    }
    
    func itemArrayTableDidLike(_ data: RssData)
    {
        print("ChannelVC --> ItemArrayTV, did like:  \(data.Title!)");
        
        data.Mark = DaoHandle.SET;
        
        dao = nil
        dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "ChannelVC");
        dao!.updateData(data);
    }
    
    func itemArrayTableWillUnLike(_ data: RssData)
    {
        print("ChannelVC --> ItemArrayTV, will unlike:  \(data.Title!)");
        
    }
    
    func itemArrayTableDidUnLike(_ data: RssData)
    {
        print("ChannelVC --> ItemArrayTV, did unlike:  \(data.Title!)");
        
        data.Mark = DaoHandle.UNSET;
        
        dao = nil
        dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "ChannelVC");
        dao!.updateData(data);
    }
}
