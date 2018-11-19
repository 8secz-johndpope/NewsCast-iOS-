//
//  SubscribeViewController.swift
//  MyApp
//
//  Created by Jose Adams on 2018/10/8.
//  Copyright © 2018 Jose Adams. All rights reserved.
//

import UIKit
import Toast_Swift

class SubscribeViewController: UIViewController, UITextFieldDelegate {

    
    /*DATA*/
    var headDataFromDAO: RssData?;
    var dataArrayFromDAO: [RssData]?;
    var headDataFromXML: RssData?;
    var dataArrayFromXML: [RssData]?;
    
    /*Delegate*/
    var easyArrayTV: EasyArrayTableViewAdapter?;

    /*HANDLE*/
    var xml: XmlHandle?;
    var dao: DaoHandle?;
    
    /*NotificationCenter*/
    let notice = NotificationCenter.default;
    var observer: NSObjectProtocol?
    
    /* UI Logic */
    var isKeyboardShown: Bool?;
    var heightOfKeyboardFrame: CGFloat?;
    var durationOfKeyboardAnimation: Double?;
    let editorStatus = ["toFetch":0, "toClear":1, "toAdd":2, "toStandby":3, "toShow":4];
    
    /*Timer*/
    var timer: Timer?;
    
    /* Storyboard */
    
    @IBOutlet var myTableView: UITableView!
    @IBOutlet var myToolBar: UIView!
    @IBOutlet var myBack: UIButton!
    @IBOutlet weak var myClear: UIButton!
    @IBOutlet weak var myAdd: UIButton!
    @IBOutlet weak var myFetch: UIButton!
    @IBOutlet var myTextField: UITextField!
    @IBOutlet var myTitle: UILabel!
    @IBOutlet var myToolBarBottom: NSLayoutConstraint!
    @IBOutlet var myIndicator: UIActivityIndicatorView!
    
    
    @IBAction func myBack(_ sender: UIButton) {
        
        if isKeyboardShown == true
        {
            isKeyboardShown = false;
            
            /* to dimiss keyboard here */
            
            myTextField.resignFirstResponder();
        }
        else
        {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func myClear(_ sender: UIButton)
    {
        myTitle.text = "Subscription";
        myTextField.text = "";
        myTableView.isHidden = true;
    }
    
    
    @IBAction func myAdd(_ sender: UIButton)
    {
        setEditorButton(status: editorStatus["toAdd"] ?? 999 );
        
        myTextField.resignFirstResponder(); // to dismiss the keyboard...
        
        showMyIndicator(true);
        
        dao = nil 
        dao = DaoHandle(Table: DaoHandle.FEEDLIST, Response: "SubscribeVC");
        dao!.insertData(headDataFromXML!);
    }
    
    @IBAction func myFetch(_ sender: UIButton) {
        
        let source = myTextField.text?.trimmingCharacters(in: .whitespaces);
        
        if checkURL(source)
        {
            setEditorButton(status: editorStatus["toFetch"] ?? 999 );
            
            myTextField.resignFirstResponder(); // to dismiss the keyboard...
            
            showMyIndicator(true);
            
            xml = nil;
            xml = XmlHandle(Url: source!, Response: "SubscribeVC");
            xml!.proceed();
        }
        else
        {
            if isKeyboardShown == true
            {
                self.view.makeToast("invalid url address", duration: 1.0, position: .center);
            }
            else
            {
                self.view.makeToast("invalid url address", duration: 1.0, position: .bottom);
            }
        }
    }
    
    /* Life Cycle */
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("SubscribeViewController, viewDidLoad");
        
        // Do any additional setup after loading the view.
        
        // the following part won't leave here for certain, think twice before move them.
        
        myTextField.delegate = self;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        print("SubscribeViewController, viewWillAppear");
        
        initView();
        addObserver();
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        print("SubscribeViewController, viewDidAppear");
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        print("SubscribeViewController, viewWillDisappear");
        
        delObserver();
        
        if xml != nil
        {
            xml!.cancel();
            
            xml = nil;
        }
        
        dao = nil;
        
        showMyIndicator(false);
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        print("SubscribeViewController, viewDidDisappear");
        
        notice.removeObserver(self);
    }
    
    /* delegates and listener */
    
    /*
     *  https://www.jianshu.com/p/9367d6b5fcad
     */
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        print("SubscribeViewController, textFieldShouldReturn");
        
        hideKeyboard();
        
        return true;
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        print("SubscribeViewController, textFieldShouldBeginEditing");
        
        return true;
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        print("SubscribeViewController, textFieldDidBeginEditing");
        
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        
        print("SubscribeViewController, textFieldShouldEndEditing");
        
        return true;
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        
        print("SubscribeViewController, textFieldDidEndEditing");

    }
    
    /*
     *  https://developer.apple.com/documentation/uikit/uiwindow/keyboard_notification_user_info_keys
     *  https://stackoverflow.com/questions/32087809/how-to-change-bottom-layout-constraint-in-ios-swift
     *  https://stackoverflow.com/questions/31774006/how-to-get-height-of-keyboard
     *  https://www.raywenderlich.com/5255-basic-uiview-animation-tutorial-getting-started
     */
    
    @objc func keyboardWillShow(notification: NSNotification)
    {
        let userInfo = notification.userInfo!;
        
        let keyboardFrame = userInfo["UIKeyboardFrameBeginUserInfoKey"] as! NSValue;
        
        heightOfKeyboardFrame = keyboardFrame.cgRectValue.height;
        
        print("SubscribeVC --> KeyBoard Frame Height: \(heightOfKeyboardFrame!)");
        
        let keyboardAnimation = userInfo["UIKeyboardAnimationDurationUserInfoKey"] as! NSNumber;
        
        durationOfKeyboardAnimation = keyboardAnimation.doubleValue;
        
        print("SubscribeVC --> KeyBoard Animation Duration: \(durationOfKeyboardAnimation!)");
        
        UIView.animate(withDuration: durationOfKeyboardAnimation!) {
            
            self.myToolBarBottom.constant = self.heightOfKeyboardFrame!;
        }
        
        isKeyboardShown = true;
    }
    
    @objc func keyboardWillHide(notification: NSNotification)
    {
        let userInfo = notification.userInfo!;
        
        let keyboardAnimation = userInfo["UIKeyboardAnimationDurationUserInfoKey"] as! NSNumber;
        
        durationOfKeyboardAnimation = keyboardAnimation.doubleValue;
        
        print("SubscribeVC --> KeyBoard Animation Duration: \(durationOfKeyboardAnimation!)");
        
        UIView.animate(withDuration: durationOfKeyboardAnimation!) {
            
            self.myToolBarBottom.constant = 0.0;
        }
        
        isKeyboardShown = false;
    }

    func hideKeyboard()
    {
        self.view.endEditing(true);
        
        isKeyboardShown = false;
        
        myTextField.resignFirstResponder();
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
        myTitle.text = "Subscription";
        
        myTextField.text = "";
        
        myTableView.isHidden = true;
        
        setEditorButton(status: editorStatus["toStandby"] ?? 999);
        
        showMyIndicator(false);
    }
    
    func addObserver()
    {
        print("SubscribeVC --> adding observer");
        
        notice.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil);
        notice.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil);
        
        observer = notice.addObserver(forName: Notification.Name(rawValue: "SubscribeVC"), object: nil, queue: OperationQueue.main) { (notification) in
            
            let userInfo = notification.userInfo as! [String : Any];
            
            print("SubscribeVC --> userInfo: \(userInfo)");
            
            if let message = userInfo["DaoHandle"] as! String?
            {
                self.showMyIndicator(false);
                
                switch(message)
                {
                case "INSERTED":
                    self.showMyIndicator(true);
                    self.dao = nil;
                    self.dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "SubscribeVC");
                    self.dao!.batchInsertDataWithUpdate(self.dataArrayFromXML!);
                    break;
                case "BATCH_INSERTED":
                    self.view.makeToast("rss is added", duration: 1.0, position: .bottom);
                    self.setEditorButton(status: self.editorStatus["toStandby"] ?? 666);
                    break;
                case "EXISTED":
                    self.view.makeToast("rss is existed", duration: 1.0, position: .bottom);
                    self.setEditorButton(status: self.editorStatus["toStandby"] ?? 666);
                    break;
                default:
                    break;
                }
            }
            else if let message = userInfo["XmlHandle"] as! String?
            {
                self.showMyIndicator(false);
                
                switch(message)
                {
                case "FETCHED":
                    self.view.makeToast("rss is fetched", duration: 1.0, position: .bottom);
                    self.dataArrayFromXML = self.xml!.RssDataArray;
                    let size = self.dataArrayFromXML!.count;
                    print("SubscribeVC --> HeadDataArray's size: \(size)");
                    self.headDataFromXML = self.dataArrayFromXML!.remove(at: 0);
                    self.myTitle.text = self.headDataFromXML!.Title!;
                    // creating the delegate object and passing the data
                    self.easyArrayTV = EasyArrayTableViewAdapter(self.dataArrayFromXML!);
                    // setting the delegate object to tableView
                    self.myTableView.isHidden = false;
                    self.myTableView.dataSource = self.easyArrayTV!;
                    self.myTableView.reloadData();
                    self.setEditorButton(status: self.editorStatus["toShow"] ?? 999);
                    break;
                case "EMPTY", "FAILED":
                    self.view.makeToast("unsupported rss", duration: 1.0, position: .bottom);
                    self.myTableView.isHidden = true;
                    self.setEditorButton(status: self.editorStatus["toStandby"] ?? 999);
                    break;
                default:
                    break;
                }
            }
        }
    }
    
    func delObserver()
    {
        print("SubscribeVC --> removing observer");
        
        if observer != nil
        {
            notice.removeObserver(observer!);
        }
        
        notice.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil);
        notice.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil);
    }
    
    func setEditorButton(status: Int)
    {
        switch(status)
        {
        case editorStatus["toFetch"]:
            myBack.isEnabled = false;
            myClear.isEnabled = false;
            myAdd.isEnabled = false;
            myFetch.isEnabled = false;
            break;
        case editorStatus["toClear"]:
            myBack.isEnabled = true;
            myClear.isEnabled = true;
            myAdd.isEnabled = false;
            myFetch.isEnabled = false;
            break;
        case editorStatus["toAdd"]:
            myBack.isEnabled = false;
            myClear.isEnabled = false;
            myAdd.isEnabled = false;
            myFetch.isEnabled = false;
            break;
        case editorStatus["toStandby"]:
            myBack.isEnabled = true;
            myClear.isEnabled = true;
            myAdd.isEnabled = false;
            myFetch.isEnabled = true;
            break;
        case editorStatus["toShow"]:
            myBack.isEnabled = true;
            myClear.isEnabled = true;
            myAdd.isEnabled = true;
            myFetch.isEnabled = true;
                break;
        default:
            myBack.isEnabled = true;
            myClear.isEnabled = false;
            myAdd.isEnabled = false;
            myFetch.isEnabled = false;
            break;
        }
    }
    
    func checkURL(_ source: String?) -> Bool
    {
        if source == nil
        {
            return false
        }
        
        guard let url = URL(string: source!) else
        {
            return false;
        }
        
        let lastPathSeg = url.lastPathComponent;
        
        if lastPathSeg.hasSuffix(".xml") || lastPathSeg.hasSuffix(".rss")
        {
            return true;
        }
        else
        {
            return false;
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
    
}
