//
//  DatelistViewController.swift
//  MyApp
//
//  Created by Jose Adams on 2018/10/11.
//  Copyright © 2018 Jose Adams. All rights reserved.
//

import UIKit

class DatelistViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate
{

    /*UI LOGIC*/
    var isItemArrayDESC: Bool = false;
    var dateToShowFromDataBase: String?;
    var dateStringArray: [String]?;
    
    /*DATA*/
    var itemDataFromDAO: RssData?;
    var itemArrayFromDAO: [RssData]?;
    var dateArray: [String]?;
    
    /*Delegate*/
    var itemArrayTV: ItemArrayTableViewAdapter?;
    
    /*HANDLE*/
    var dao: DaoHandle?;
    
    /*Timer*/
    var timer: Timer?;
    
    /*NotificationCenter*/
    let notice = NotificationCenter.default;
    var observer: NSObjectProtocol?
    
    /*DispatchQueue*/
    let queue = DispatchQueue.main;
    
    /*View Controller Manager*/
    let vcBridge = ViewControllerManager.Bridge;
    
    /* Storyboard */
    
    @IBOutlet var myPickerView: UIPickerView!
    @IBOutlet weak var myReload: UIButton!
    @IBOutlet weak var myTable: UITableView!
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet var myIndicator: UIActivityIndicatorView!
    @IBOutlet var myLabel: UILabel!
    
    @IBAction func myReload(_ sender: UIButton)
    {
        myReload.isEnabled = false;
        
        let vc = vcBridge.ReloadVC;
        
        vc.modalTransitionStyle = UIModalTransitionStyle.crossDissolve;
        vc.modalPresentationStyle = .fullScreen;
        
        self.present(vc, animated: true, completion: nil);
    }
    
    /* Life Cycle */
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("DatelistViewController, viewDidLoad");
        
        // Do any additional setup after loading the view.
        
        let today = Date();
        
        dateToShowFromDataBase = convertDateToStringFuzzy(today);
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        print("DatelistViewController, viewWillAppear");
        
        initView();
        addObserver();
        initLoading();
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        print("DatelistViewController, viewDidAppear");
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        print("DatelistViewController, viewWillDisappear");
        
        delObserver();
        
        dao = nil;
        
        showMyIndicator(false);
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        print("DatelistViewController, viewDidDisappear");
        
    }
    
    /* Delegate */
    
    // how many columns
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    // how many rows for each column
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return dateArray!.count;
    }
    
    // title for the specific row
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return dateArray![row];
    }
    
    // which row is choosen
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        dateToShowFromDataBase = dateArray![row];
        
        print("DatelistVC --> date picked: \(dateToShowFromDataBase!)");
        
        initLoading();
    }
    
    // change the color of title in specific row
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        
        return NSAttributedString(string: dateArray![row], attributes: [NSAttributedString.Key.foregroundColor:UIColor.white]);
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
        
        showMyIndicator(false);
        
        let cal = Calendar.current;
        let format = DateFormatter();
        
        format.locale = Locale.current;
        format.dateFormat = "yyyy-MM-dd";
        
        let date = Date();
        let dateString = format.string(from: date);
        
        dateArray = [String]();
        dateArray!.append(dateString);
        
        if dateToShowFromDataBase == nil
        {
            dateToShowFromDataBase = dateString;
        }
        
        for index in 1...9
        {
            dateArray!.append(format.string(from: cal.date(byAdding: .day, value: -index, to: date)!));
        }
        
        myPickerView.delegate = self;
        myPickerView.dataSource = self;
        myPickerView.reloadAllComponents();
    }
    
    func addObserver()
    {
        print("DatelistVC --> adding observer");
        
        observer = notice.addObserver(forName: Notification.Name(rawValue: "DatelistVC"), object: nil, queue: OperationQueue.main) { (notification) in
            
            let userInfo = notification.userInfo as! [String : Any];
            
            print("DatelistVC --> userInfo: \(userInfo)");
            
            if let message = userInfo["DaoHandle"] as! String?
            {
                self.showMyIndicator(false);
                
                switch(message)
                {
                case "FETCHED":
                    // retrieve data array
                    self.itemArrayFromDAO = self.dao!.RssDataArray;
                    let size = self.itemArrayFromDAO!.count;
                    print("DatelistVC --> ItemDataArray's size: \(size)");
                    // creating the delegate object and passing the data
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
                    break;
                case "EMPTY":
                    self.showMyTable(nil);
                    self.showMyLabel(true);
                    break;
                case "UPDATED", "UPDATE_FAILED":
                    self.initLoading();
                    break;
                default:
                    break;
                }
            }
        }
    }
    
    func delObserver()
    {
        print("DatelistVC --> removing observer");
        
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
        
        myTableView.isHidden = true;
        
        isItemArrayDESC = true;
        
        dao = nil;
        dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "DatelistVC");
        dao!.fetchDataArrayFuzzy(Column: DaoHandle.DATE, Like: dateToShowFromDataBase!, Order: DaoHandle.DATE, Sort: DaoHandle.DESC);
    }
    
    func convertDateToStringFuzzy(_ date: Date) -> String
    {
        let format = DateFormatter();
        format.locale = Locale.current;
        format.dateFormat = "yyyy-MM-dd";
        
        let someday = format.string(from: date);
        
        return someday;
    }
    
    func convertDateToStringPrecise(_ date: Date) -> String
    {
        let format = DateFormatter();
        format.locale = Locale.current;
        format.dateFormat = "yyyy-MM-dd HH:mm:ss";
        
        let someday = format.string(from: date);
        
        return someday;
    }
    
    func itemArrayTableDidSelect(_ data: RssData)
    {
        print("DatelistVC --> ItemArrayTV did select:  \(data.Title!)")
        
        vcBridge.Data = data;
        
        let vc = vcBridge.PlayerVC;
        
        vc.modalTransitionStyle = UIModalTransitionStyle.crossDissolve;
        vc.modalPresentationStyle = .fullScreen;
        
        self.present(vc, animated: true, completion: nil);
    }
    
    func itemArrayTableWillLike(_ data: RssData)
    {
        print("DatelistVC --> ItemArrayTV, will like:  \(data.Title!)");
        
    }
    
    func itemArrayTableDidLike(_ data: RssData)
    {
        print("DatelistVC --> ItemArrayTV, did like:  \(data.Title!)");
        
        data.Mark = DaoHandle.SET;
        
        dao = nil
        dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "DatelistVC");
        dao!.updateData(data);
    }
    
    func itemArrayTableWillUnLike(_ data: RssData)
    {
        print("DatelistVC --> ItemArrayTV, will unlike:  \(data.Title!)");
        
    }
    
    func itemArrayTableDidUnLike(_ data: RssData)
    {
        print("DatelistVC --> ItemArrayTV, did unlike:  \(data.Title!)");
        
        data.Mark = DaoHandle.UNSET;
        
        dao = nil
        dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "DatelistVC");
        dao!.updateData(data);
    }
}
