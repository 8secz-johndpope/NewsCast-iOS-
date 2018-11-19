//
//  PersonViewController.swift
//  MyApp
//
//  Created by Jose Adams on 2018/10/11.
//  Copyright © 2018 Jose Adams. All rights reserved.
//

import UIKit
import Firebase
import Toast_Swift

class PersonalViewController: UIViewController, UITextFieldDelegate, URLSessionDownloadDelegate  {
    
    /* Attributes */
    
    /** @var handle
     @brief The handler for the auth state listener, to allow cancelling later.
     */
    var handle: AuthStateDidChangeListenerHandle?
    
    /*NotificationCenter*/
    let notice = NotificationCenter.default;
    var observer: NSObjectProtocol?
    
    /*handle*/
    var download: DownloadHandle?;
    
    /* UI Logic */
    var myInputBarNormalHeight: CGFloat?;
    var myStatusBarNormalHeight: CGFloat?;
    var heightOfKeyboardFrame: CGFloat?;
    var durationOfKeyboardAnimation: Double?;
    var isMyEmailHitFirst: Bool = false;
    var isMyPasswordHitFirst: Bool = false;
    var isKeyboardShown: Bool = false;
    var isMyEmailEditing: Bool = false;
    var isMyPasswordEditing: Bool = false;
    
    /* Firebase */
    var userID: String?;
    var userInfo: User?;
    var firebaseUploadTask: StorageUploadTask?;
    var firebaseDownloadTask: StorageDownloadTask?;
    var firebaseObservableTask: StorageObservableTask?;
    let sqliteFileName = "newscast.sqlite"
    let Agent = "Mozilla/5.0 (Android 8.0.0; Mobile; rv:62.0) Gecko/62.0 Firefox/62.0";
    
    /* Storyboard */
    
    @IBOutlet weak var myIndicator: UIActivityIndicatorView!
    @IBOutlet weak var myImage: UIImageView!
    @IBOutlet weak var myButtonBarBottom: NSLayoutConstraint!
    @IBOutlet weak var myBackup: UIButton!
    @IBOutlet weak var myStatusBarHeight: NSLayoutConstraint!
    @IBOutlet weak var myInputBarHeight: NSLayoutConstraint!
    @IBOutlet weak var myRestore: UIButton!
    
    @IBOutlet weak var myUserInfo: UILabel!
    @IBOutlet weak var myUserID: UILabel!
    
    @IBOutlet weak var myEmail: UITextField!
    @IBOutlet weak var myPassword: UITextField!
    
    @IBOutlet weak var mySignIn: UIButton!
    @IBOutlet weak var mySignOut: UIButton!
    @IBOutlet weak var myCreate: UIButton!
    @IBOutlet weak var myVerify: UIButton!
    
    @IBOutlet weak var myInputBar: UIView!
    @IBOutlet weak var myStatusBar: UIView!
    
    @IBAction func myBackup(_ sender: UIButton) {
        
        if userInfo != nil && userID != nil
        {
            self.setFirebaseButtons(false);
            
            self.showProcessing(true);
            
            self.view.makeToast("uploading", duration: 1.0, position: ToastPosition.bottom, title: "backup to Firebase", image: nil, style: ToastStyle.init(), completion: nil);
            
            //Get a reference to the storage service
            let storage = Storage.storage();
            
            // Points to the root reference
            let storageRef = storage.reference();
            
            // Points to "uid" as folder name
            let folderRef = storageRef.child(userID!);
            
            // Points to "<uid>/rss_storage.sqlite"
            // Note that you can use variables to create child values
            let fileRef = folderRef.child(sqliteFileName);
            
            // File located on disk
            let stringPath = "\(NSHomeDirectory())/Documents/\(sqliteFileName)";
            let localFile = URL(fileURLWithPath: stringPath);
            
            // Upload the file to the path...
            firebaseUploadTask = fileRef.putFile(from: localFile);
            
            firebaseUploadTask!.resume();
            
            firebaseUploadTask!.observe(.success) { snapshot in
                
                self.setFirebaseButtons(true);

                self.showProcessing(false);
                
                self.view.makeToast("successful", duration: 1.0, position: ToastPosition.bottom, title: "backup to Firebase", image: nil, style: ToastStyle.init(), completion: nil);
            
                self.firebaseUploadTask!.removeAllObservers();
            }
            
            firebaseUploadTask!.observe(.failure) { snapshot in
                
                self.setFirebaseButtons(true);
                
                self.showProcessing(false);
                
                if let error = snapshot.error as NSError?
                {
                    switch (StorageErrorCode(rawValue: error.code)!)
                    {
                    case .objectNotFound:
                        self.view.makeToast("file not found", duration: 1.0, position: ToastPosition.bottom, title: "backup to Firebase", image: nil, style: ToastStyle.init(), completion: nil);
                        break
                    case .unauthorized:
                        self.view.makeToast("unauthorised access", duration: 1.0, position: ToastPosition.bottom, title: "backup to Firebase", image: nil, style: ToastStyle.init(), completion: nil);
                        break
                    case .cancelled:
                        self.view.makeToast("uploading cancelled", duration: 1.0, position: ToastPosition.bottom, title: "backup to Firebase", image: nil, style: ToastStyle.init(), completion: nil);
                        break
                    case .unknown:
                        self.view.makeToast("unknown error", duration: 1.0, position: ToastPosition.bottom, title: "backup to Firebase", image: nil, style: ToastStyle.init(), completion: nil);
                        break
                    default:
                        self.view.makeToast("error occrus", duration: 1.0, position: ToastPosition.bottom, title: "backup to Firebase", image: nil, style: ToastStyle.init(), completion: nil);
                        break
                    }
                }
                
                self.firebaseUploadTask!.removeAllObservers();
            }
        }
    }
    
    @IBAction func myRestore(_ sender: UIButton) {
        
        if userInfo != nil && userID != nil
        {
            self.setFirebaseButtons(false);
            
            self.showProcessing(true);
            
            self.view.makeToast("downloading", duration: 1.0, position: ToastPosition.bottom, title: "restore from Firebase", image: nil, style: ToastStyle.init(), completion: nil);
            
            //Get a reference to the storage service
            let storage = Storage.storage();
            
            // Points to the root reference
            let storageRef = storage.reference();
            
            // Points to "uid" as folder name
            let folderRef = storageRef.child(userID!);
            
            // Points to "<uid>/rss_storage.sqlite"
            // Note that you can use variables to create child values
            let fileRef = folderRef.child(sqliteFileName);
            
            fileRef.downloadURL(completion: { (url, error) in
                
                if let url = url
                {
                    print("PersonalVC --> download url: \(url)");
                    
                    let urlString = "\(url)";
                    
                    print("PersonalVC --> download string url: \(urlString)");
                    
                    self.download = nil
                    self.download = DownloadHandle(FileLink: urlString, FileName: self.sqliteFileName, Response: "PersonalVC");
                    self.download!.proceed();
                }
                else
                {
                    self.setFirebaseButtons(true);
                    
                    self.showProcessing(false);
                    
                    self.view.makeToast("file not found", duration: 1.0, position: ToastPosition.bottom, title: "restore from Firebase", image: nil, style: ToastStyle.init(), completion: nil);
                }
            });
            
            // Create local filesystem URL
//            let stringPath = "\(NSHomeDirectory())/Documents/\(sqliteFileName)";
//            let localFile = URL(fileURLWithPath: stringPath);
            
            // Download to the local filesystem
            //firebaseDownloadTask = fileRef.write(toFile: localFile);
            
//            firebaseDownloadTask!.resume();
//
//            firebaseDownloadTask!.observe(.success) { snapshot in
//
//                self.setFirebaseButtons(true);
//
//                self.showProcessing(false);
//
//                self.view.makeToast("successful", duration: 1.0, position: ToastPosition.bottom, title: "restore from Firebase", image: nil, style: ToastStyle.init(), completion: nil);
//
//                self.firebaseDownloadTask!.removeAllObservers();
//            }
            
            // Errors only occur in the "Failure" case
//            firebaseDownloadTask!.observe(.failure) { snapshot in
//
//                self.setFirebaseButtons(true);
//
//                self.showProcessing(false);
//
//                if let error = snapshot.error as NSError?
//                {
//                    switch (StorageErrorCode(rawValue: error.code)!)
//                    {
//                    case .objectNotFound:
//                        self.view.makeToast("file not found", duration: 1.0, position: ToastPosition.bottom, title: "restore from Firebase", image: nil, style: ToastStyle.init(), completion: nil);
//                        break
//                    case .unauthorized:
//                        self.view.makeToast("unauthorised access", duration: 1.0, position: ToastPosition.bottom, title: "restore from Firebase", image: nil, style: ToastStyle.init(), completion: nil);
//                        break
//                    case .cancelled:
//                        self.view.makeToast("downloading cancelled", duration: 1.0, position: ToastPosition.bottom, title: "restore from Firebase", image: nil, style: ToastStyle.init(), completion: nil);
//                        break
//                    case .unknown:
//                        self.view.makeToast("unknown error", duration: 1.0, position: ToastPosition.bottom, title: "restore from Firebase", image: nil, style: ToastStyle.init(), completion: nil);
//                        break
//                    default:
//                        self.view.makeToast("error occrus", duration: 1.0, position: ToastPosition.bottom, title: "restore from Firebase", image: nil, style: ToastStyle.init(), completion: nil);
//                        break
//                    }
//                }
//
//                self.firebaseDownloadTask!.removeAllObservers();
//            }
        }
    }
    
    @IBAction func mySignIn(_ sender: UIButton) {
        
        hideKeyboard();
        
        if let email = self.myEmail.text, let password = self.myPassword.text
        {
            showProcessing(true);
            
            // [START headless_email_auth]
            Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                
                self.showProcessing(false);
                
                // [START_EXCLUDE]
                
                if let error = error
                {
                    self.view.makeToast("Error \(error.localizedDescription)", duration: 1.0, position: .bottom, title: "Sign-In: ", image: nil, style: ToastStyle.init(), completion: nil);
                
                    print("PersonVC --> sign-in: \(error.localizedDescription)");
                    
                    return
                }
                
                if let user = user
                {
                    print("PersonVC --> sign-in: \(user)");
                
                }
                
                self.view.makeToast("successful!", duration: 1.0, position: .bottom, title: "Sign-In: ", image: nil, style: ToastStyle.init(), completion: nil);
                
                // [END_EXCLUDE]
            }
            // [END headless_email_auth]
        }
        else
        {
            self.view.makeToast("Email or Password is invalid!", duration: 1.0, position: .bottom, title: "Sign-In: ", image: nil, style: ToastStyle.init(), completion: nil);
        }
        
    }
    
    @IBAction func myCreate(_ sender: UIButton) {
        
        hideKeyboard();
        
        if let email = self.myEmail.text, let password = self.myPassword.text
        {
            self.showProcessing(true);
            
            // [START create_user]
            
            Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
                
                self.showProcessing(false);
                
                // [START_EXCLUDE]
                
                if let error = error
                {
                    self.view.makeToast("Error \(error.localizedDescription)", duration: 1.0, position: .bottom, title: "Create Account: ", image: nil, style: ToastStyle.init(), completion: nil);
                    
                    print("PersonVC --> create: \(error.localizedDescription)");
                    
                    return
                }
                
                guard let email = authResult?.user.email else
                {
                    self.view.makeToast("Email is invalid!", duration: 1.0, position: .bottom, title: "Create Account: ", image: nil, style: ToastStyle.init(), completion: nil);
                
                    return
                }
                
                print("PersonVC --> create: \(email), created!");
                
                self.view.makeToast("successful!", duration: 1.0, position: .bottom, title: "Create Account: ", image: nil, style: ToastStyle.init(), completion: nil);
            
                // [END_EXCLUDE]
                guard let user = authResult?.user else { return }
                
                print("PersonVC --> create: \(user), authorised!");
            }
            // [END create_user]
        }
        else
        {
            self.view.makeToast("Email or Password is invalid!", duration: 1.0, position: .bottom, title: "Sign-In: ", image: nil, style: ToastStyle.init(), completion: nil);
        }
    }
    
    @IBAction func myVerify(_ sender: UIButton)
    {
        self.showProcessing(true);
        
        // [START send_verification_email]
        Auth.auth().currentUser?.sendEmailVerification { (error) in
            
            self.showProcessing(false);
            
            // [START_EXCLUDE]
            
            if let error = error
            {
                self.view.makeToast("Error: \(error.localizedDescription)", duration: 1.0, position: .bottom, title: "Verify Email: ", image: nil, style: ToastStyle.init(), completion: nil);
                
                print("PersonVC --> verify: \(error.localizedDescription)");
                
                return
            }
            
            self.view.makeToast("Your request is sent", duration: 1.0, position: .bottom, title: "Verify Email: ", image: nil, style: ToastStyle.init(), completion: nil);
            
            // [END_EXCLUDE]
        }
        // [END send_verification_email]
    }
    
    @IBAction func mySignOut(_ sender: UIButton) {
        
        self.showProcessing(true);
        
        let firebaseAuth = Auth.auth();
        
        do
        {
            self.showProcessing(false);
            
            try firebaseAuth.signOut()
            
            self.view.makeToast("successful!", duration: 1.0, position: .bottom, title: "Sign-Out: ", image: nil, style: ToastStyle.init(), completion: nil);
        }
        catch let signOutError as NSError
        {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    /* Life Cycle */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("PersonalViewController, viewDidLoad");
        
        // Do any additional setup after loading the view.
        
        myEmail.delegate = self;
        myPassword.delegate = self;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        print("PersonalViewController, viewWillAppear");
        
        addObserver();
        
        notice.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil);
        notice.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil);

        myStatusBarNormalHeight = myStatusBarHeight.constant;
        myInputBarNormalHeight = myInputBarHeight.constant;
        
        self.showProcessing(true);
        
        // [START get_user_profile]
        self.userInfo = Auth.auth().currentUser
        // [END get_user_profile]
        
        // [START user_profile]
        self.updateUI(self.userInfo);
        // [END user_profile]
        
        self.showProcessing(false);
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        print("PersonalViewController, viewDidAppear");
        
        hideKeyboard();
        
        // [START auth_listener]
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            
            // [START_EXCLUDE]
            
            print("PersonalVC --> Firebase, State Did Change");
            
            print("PersonalVC --> Firebase, auth: \(auth)");
            
            print("PersonalVC --> Firebase, user: \(user)");
            
            self.userInfo = user;
            
            self.updateUI(self.userInfo);
            
            // [END_EXCLUDE]
        }
        // [END auth_listener]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        print("PersonalViewController, viewWillDisappear");
    
        delObserver();
        
        notice.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil);
        notice.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil);
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        print("PersonalViewController, viewDidDisappear");
        
        // [START remove_auth_listener]
        Auth.auth().removeStateDidChangeListener(handle!)
        // [END remove_auth_listener]
        
        if firebaseUploadTask != nil
        {
            firebaseUploadTask!.removeAllObservers();
            firebaseUploadTask!.cancel();
            firebaseUploadTask = nil;
        }
        
        if firebaseDownloadTask != nil
        {
            firebaseDownloadTask!.removeAllObservers();
            firebaseDownloadTask!.cancel();
            firebaseDownloadTask = nil;
        }
    }
    
    /* delegates and listener */
    
    /*
     *  https://www.jianshu.com/p/9367d6b5fcad
     */
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        let targetFileURL = URL(fileURLWithPath: "\(NSHomeDirectory())/Documents/\(sqliteFileName)" )   /// <-- the running environment
        
        let sourceDataURL = NSData(contentsOf: location)
        
        if sourceDataURL!.write(to: targetFileURL, atomically: true)
        {
            self.setFirebaseButtons(true);
            
            self.showProcessing(false);
            
            downloadTask.cancel();
            
            session.invalidateAndCancel();
            
            self.view.makeToast("successful", duration: 1.0, position: ToastPosition.bottom, title: "restore from Firebase", image: nil, style: ToastStyle.init(), completion: nil);
        }
        else
        {
            self.setFirebaseButtons(true);
            
            self.showProcessing(false);
            
            downloadTask.cancel();
            
            session.invalidateAndCancel();
            
            self.view.makeToast("writing failed", duration: 1.0, position: ToastPosition.bottom, title: "restore from Firebase", image: nil, style: ToastStyle.init(), completion: nil);
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if error != nil
        {
            print("PersonalVC --> downloading error: \(error)");
            
            self.setFirebaseButtons(true);
            
            self.showProcessing(false);
            
            self.view.makeToast("downloading failed", duration: 1.0, position: ToastPosition.bottom, title: "restore from Firebase", image: nil, style: ToastStyle.init(), completion: nil);
            
            task.cancel();
            
            session.invalidateAndCancel();
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        print("PersonalViewController, textFieldShouldReturn");
        
        hideKeyboard();
        
        return true;
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        print("PersonalViewController, textFieldShouldBeginEditing");
        
        if !isMyEmailHitFirst && !isMyPasswordHitFirst
        {
            if textField.placeholder == "Email"
            {
                isMyEmailHitFirst = true;
            
            }
            else if textField.placeholder == "Password"
            {
                isMyPasswordHitFirst = true;
            
            }
        }
        
        print("isMyPasswordHitFirst: \(isMyPasswordHitFirst)");
        print("isMyEmailHitFirst: \(isMyEmailHitFirst)");
        
        return true;
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        print("PersonalViewController, textFieldDidBeginEditing");
        
        if textField.placeholder == "Email"
        {
            isMyEmailEditing = true;
        }
        else if textField.placeholder == "Password"
        {
            isMyPasswordEditing = true;
        }
        
        print("isMyEmailEditing: \(isMyEmailEditing)");
        print("isMyPasswordEditing: \(isMyPasswordEditing)");
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        
        print("PersonalViewController, textFieldShouldEndEditing");
        
        return true;
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        
        print("PersonalViewController, textFieldDidEndEditing");
        
        if textField.placeholder == "Email"
        {
            isMyEmailEditing = false;
        }
        else if textField.placeholder == "Password"
        {
            isMyPasswordEditing = false;
        }
        
        print("isMyEmailEditing: \(isMyEmailEditing)");
        print("isMyPasswordEditing: \(isMyPasswordEditing)");
        
        if !isMyEmailEditing && !isMyPasswordEditing
        {
            hideKeyboard();
        }
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
        
        print("PersonVC --> KeyBoard Frame Height: \(heightOfKeyboardFrame!)");
        
        let keyboardAnimation = userInfo["UIKeyboardAnimationDurationUserInfoKey"] as! NSNumber;
        
        durationOfKeyboardAnimation = keyboardAnimation.doubleValue;
        
        print("PersonVC --> KeyBoard Animation Duration: \(durationOfKeyboardAnimation!)");
        
        UIView.animate(withDuration: durationOfKeyboardAnimation!) {
            
            self.myButtonBarBottom.constant = -(self.heightOfKeyboardFrame!);
        }
        
        isKeyboardShown = true;
    }
    
    @objc func keyboardWillHide(notification: NSNotification)
    {
        let userInfo = notification.userInfo!;
        
        let keyboardAnimation = userInfo["UIKeyboardAnimationDurationUserInfoKey"] as! NSNumber;
        
        durationOfKeyboardAnimation = keyboardAnimation.doubleValue;
        
        print("PersonVC --> KeyBoard Animation Duration: \(durationOfKeyboardAnimation!)");
        
        UIView.animate(withDuration: durationOfKeyboardAnimation!) {
            
            self.myButtonBarBottom.constant = 0.0;
        }
        
        isKeyboardShown = false;
    }
    
    func hideKeyboard()
    {   
        self.view.endEditing(true);
        
        isKeyboardShown = false;
        
        if isMyEmailHitFirst
        {
            print("PersonVC --> My Email to resign");
            
            myEmail.resignFirstResponder();
            
        }
        else if isMyPasswordHitFirst
        {
            print("PersonVC --> My Password to resign");
            
            myPassword.resignFirstResponder();
        }
        
        isMyEmailHitFirst = false;
        isMyPasswordHitFirst = false;
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
        print("PersonalVC --> adding observer");
        
        observer = notice.addObserver(forName: Notification.Name(rawValue: "PersonalVC"), object: nil, queue: OperationQueue.main) { (notification) in
            
            let userInfo = notification.userInfo as! [String : Any];
            
            print("PersonalVC --> userInfo: \(userInfo)");
            
            if let message = userInfo["Download_Message"] as! String?
            {
                self.setFirebaseButtons(true);
                self.showProcessing(false);
                
                switch(message)
                {
                case "DOWNLOADED_AND_SAVED":
                    self.view.makeToast("successful", duration: 1.0, position: ToastPosition.bottom, title: "restore from Firebase", image: nil, style: ToastStyle.init(), completion: nil);
                    break;
                case "DOWNLOADED_BUT_SAVE_FAILED", "DOWNLOAD_FAILED":
                    self.view.makeToast("downloading error", duration: 1.0, position: ToastPosition.bottom, title: "restore from Firebase", image: nil, style: ToastStyle.init(), completion: nil);
                    break;
                default:
                    print("PersonalVC --> Unexpected Error Happened in DownloadHandle");
                    break;
                }
            }
            else if let progress = userInfo["Download_Progress"] as! Float?
            {
                print("PlayerVC --> Downloading Progress: \(progress)");
                
            }
        }
    }
    
    func delObserver()
    {
        print("PersonalVC --> removing observer");
        
        if observer != nil
        {
            notice.removeObserver(observer!);
        }
    }

    func showProcessing(_ yes: Bool)
    {
        if yes
        {
            myIndicator.isHidden = false;
            myImage.isHidden = true;
        }
        else
        {
            myIndicator.isHidden = true;
            myImage.isHidden = false;
        }
    }
    
    func updateUI(_ user: User?)
    {
        if user == nil
        {
            self.myUserInfo.text = "";
            self.myUserID.text = ""
            self.userID = nil;
            
            self.mySignIn.isEnabled = true;
            self.myCreate.isEnabled = true;
            
            self.mySignIn.isHidden = false;
            self.myCreate.isHidden = false;
            
            self.mySignIn.alpha = 1.0;
            self.myCreate.alpha = 1.0;
            
            self.mySignOut.isEnabled = false;
            self.myVerify.isEnabled = false;
            
            self.mySignOut.isHidden = true;
            self.myVerify.isHidden = true;
            
            self.mySignOut.alpha = 0.0;
            self.myVerify.alpha = 0.0;
            
            self.myStatusBar.isHidden = true;
            self.myStatusBar.alpha = 0.0;
            self.myStatusBarHeight.constant = CGFloat(0.0);
            
            self.myInputBar.isHidden = false;
            self.myInputBar.alpha = 1.0;
            self.myInputBarHeight.constant = self.myInputBarNormalHeight!;
            
            self.setMyBackupButton(false);
            self.setMyRestoreButton(false);
        }
        else
        {
            // The user's ID, unique to the Firebase project.
            // Do NOT use this value to authenticate with your backend server,
            // if you have one. Use getTokenWithCompletion:completion: instead.
            
            self.myUserInfo.text = "Email User: \(user!.email!) (verified: \(user!.isEmailVerified))";
            self.myUserID.text = "Firebase User: \(user!.uid)"
            self.userID  = user!.uid;
            
            // [START_EXCLUDE]
            
            self.mySignIn.isEnabled = false;
            self.myCreate.isEnabled = false;
            
            self.mySignIn.isHidden = true;
            self.myCreate.isHidden = true;
            
            self.mySignIn.alpha = 0.0;
            self.myCreate.alpha = 0.0;
            
            self.mySignOut.isEnabled = true;
            self.myVerify.isEnabled = true;
            
            self.mySignOut.isHidden = false;
            self.myVerify.isHidden = false;
            
            self.mySignOut.alpha = 1.0;
            self.myVerify.alpha = 1.0;
            
            if user!.isEmailVerified
            {
                self.myVerify.isEnabled = false;
                self.myVerify.setTitle("EMAIL VERIFIED", for: UIControl.State.normal);
                self.myVerify.alpha = 0.5;
            }
            else
            {
                self.myVerify.isEnabled = true;
                self.myVerify.setTitle("VERIFY EMAIL", for: UIControl.State.normal);
                self.myVerify.alpha = 1.0;
            }
            
            self.myStatusBar.isHidden = false;
            self.myStatusBar.alpha = 1.0;
            self.myStatusBarHeight.constant = self.myStatusBarNormalHeight!;
            
            self.myInputBar.isHidden = true;
            self.myInputBar.alpha = 0.0;
            self.myInputBarHeight.constant = CGFloat(0.0);
            
            self.setMyBackupButton(true);
            self.setMyRestoreButton(true);
            
            // [END_EXCLUDE]
        }
    }
    
    func setMyBackupButton(_ enable: Bool)
    {
        if enable
        {
            myBackup.isEnabled = true;
            myBackup.alpha = 1.0;
        }
        else
        {
            myBackup.isEnabled = false;
            myBackup.alpha = 0.5;
        }
    }
    
    func setMyRestoreButton(_ enable: Bool)
    {
        if enable
        {
            myRestore.isEnabled = true;
            myRestore.alpha = 1.0;
        }
        else
        {
            myRestore.isEnabled = false;
            myRestore.alpha = 0.5;
        }
    }
    
    func setFirebaseButtons(_ enable: Bool)
    {
        if enable
        {
            mySignIn.isEnabled = true;
            mySignIn.alpha = 1.0;
            
            mySignOut.isEnabled = true;
            mySignOut.alpha = 1.0;
            
            myCreate.isEnabled = true;
            mySignOut.alpha = 1.0;
            
            if self.userInfo != nil
            {
                if self.userInfo!.isEmailVerified
                {
                    myVerify.isEnabled = false;
                    myVerify.setTitle("EMAIL VERIFIED", for: UIControl.State.normal);
                    myVerify.alpha = 0.5;
                }
                else
                {
                    myVerify.isEnabled = true;
                    myVerify.setTitle("VERIFY EMAIL", for: UIControl.State.normal);
                    myVerify.alpha = 1.0;
                }
            }
            
            myBackup.isEnabled = true;
            myBackup.alpha = 1.0;
            
            myRestore.isEnabled = true;
            myRestore.alpha = 1.0;
        }
        else
        {
            mySignIn.isEnabled = false;
            mySignIn.alpha = 0.5;
            
            mySignOut.isEnabled = false;
            mySignOut.alpha = 0.5;
            
            myCreate.isEnabled = false;
            mySignOut.alpha = 0.5;
            
            myVerify.isEnabled = false;
            myVerify.alpha = 0.5;
            
            myBackup.isEnabled = false;
            myBackup.alpha = 0.5;
            
            myRestore.isEnabled = false;
            myRestore.alpha = 0.5;
        }
    }
}
