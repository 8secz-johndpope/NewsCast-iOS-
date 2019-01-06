//
//  ViewController.swift
//  MyApp
//
//  Created by Jose Adams on 2018/10/11.
//  Copyright © 2018 Jose Adams. All rights reserved.
//

import UIKit
import AVFoundation
import Toast_Swift

class PlayerViewController: UIViewController {

    /*DATA*/
    var itemDataFromEXT: RssData?;
    var rawLink: String?;
    var webMediaLink: String?;
    var webScript: String?;
    var webMediaFile: String?;
    var localScript: String?;
    var localMediaFile: String?;
    
    /*UI Logic*/
    var willPlayMusicFromLink: Bool?;
    var willPlayMusicFromFile: Bool?;
    var totalProgressWaitedSoFar = 0;
    
    /*HANDLE*/
    var dao: DaoHandle?;
    var html: HtmlHandle?;
    var download: DownloadHandle?;
    
    /*NotificationCenter*/
    let notice = NotificationCenter.default;
    var observer: NSObjectProtocol?
    
    /*DispatchQueue*/
    let queue = DispatchQueue.main;
    
    /*Timer*/
    var timer: Timer?;
    
    /*View Controller Manager*/
    let vcBridge = ViewControllerManager.Bridge;
    
    /*
     *  http://www.hangge.com/blog/cache/detail_1668.html
     */
    
    /* PMUSIC LAYER */
    var playerItem: AVPlayerItem?
    var player: AVPlayer?
    var playerObserver: Any?;
    let playerStatus = ["toPlay":0, "toPause":1, "toStop":2, "toEject":3, "toInsert":4];
    let downloadStatus = ["downloadable":0, "downloading":1, "downloaded":2, "unavailable":3];
    var isDownloaded: Bool?;
    var isDownloading: Bool?;
    
    /* Storyboard */
    
    @IBOutlet weak var mySlider: UISlider!
    @IBOutlet weak var myDownload: UIButton!
    @IBOutlet weak var myReload: UIButton!
    @IBOutlet weak var myShare: UIButton!
    @IBOutlet weak var myStop: UIButton!
    @IBOutlet weak var myPause: UIButton!
    @IBOutlet weak var myPlay: UIButton!
    @IBOutlet weak var myProgress: UIProgressView!
    @IBOutlet weak var myMessage: UILabel!
    @IBOutlet weak var myMessageHeight: NSLayoutConstraint!
    @IBOutlet weak var myTitle: UILabel!
    @IBOutlet weak var myParent: UILabel!
    @IBOutlet weak var myCategory: UILabel!
    @IBOutlet weak var myPubDate: UILabel!
    
    @IBOutlet var myScroll: UIScrollView!
    @IBOutlet var myScript: UILabel!
    
    @IBAction func myDownload(_ sender: UIButton)
    {
        setDownloadButton(downloadStatus["downloading"]!);
        
        setReloadButton(false);
        
        setPlayerButton(playerStatus["toEject"] ?? -1);
        
        delMusicPlayer();
        
        initDownloader();
    }
    
    @IBAction func myReload(_ sender: UIButton)
    {
        setReloadButton(false);
        
        setDownloadButton(downloadStatus["unavailable"]!);
        
        setPlayerButton(playerStatus["toEject"] ?? -1);
        
        delMusicPlayer();
        
        reLoading();
    }
    
    @IBAction func myShare(_ sender: UIButton)
    {
        let link = itemDataFromEXT!.Link;
        
        if let url = URL(string: link ?? "")
        {
            if self.player != nil
            {
                self.setPlayerButton(self.playerStatus["toPause"] ?? -1);
                
                self.player!.pause();
            }
            
            self.view.makeToast("Default Browser", duration: 0.5, position: .center, title: "Open In...", image: nil, style: ToastStyle.init()) { (done) in
                
                UIApplication.shared.open(url, options: [:], completionHandler: nil);
            }
        }
    }
    
    @IBAction func myEject(_ sender: UIButton)
    {
        if isDownloading == true
        {
            delDownloader();
            
            self.view.makeToast("Download Interrupted", duration: 0.5, position: .bottom, title: nil, image: nil, style: ToastStyle.init(), completion: nil);
        }
        
        dismiss(animated: true, completion: nil);
    }
    
    @IBAction func myPlay(_ sender: UIButton)
    {
        setPlayerButton(playerStatus["toPlay"] ?? -1);
        
        player!.play();
    }
    
    @IBAction func myPause(_ sender: UIButton)
    {
        setPlayerButton(playerStatus["toPause"] ?? -1);
        
        player!.pause();
    }
    
    @IBAction func myStop(_ sender: UIButton)
    {
        setPlayerButton(playerStatus["toStop"] ?? -1);
        
        player!.pause();
        
        player!.seek(to: CMTimeMake(value: 0, timescale: 1));
        mySlider.value = 0;
    }
    
    @IBAction func mySlider(_ sender: UISlider)
    {
        let seconds : Int64 = Int64(mySlider.value);
        let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1);
        
        player!.seek(to: targetTime);
    }
    
    
    /* Life Cycle */
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("PlayerViewController, viewDidLoad");
        
        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        print("PlayerViewController, viewWillAppear");
        
        /*
         *  https://github.com/iOSDevCafe/YouTube-Example-Codes
         */
        
        myScroll.contentLayoutGuide.bottomAnchor.constraint(equalTo: myScript.bottomAnchor).isActive = true;
        
        initData();
        initView();
        addObserver();
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        print("PlayerViewController, viewDidAppear");
        
        initLoading();
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        print("PlayerViewController, viewWillDisappear");
        
        delObserver();
        delMusicPlayer();
        
        if download != nil
        {
            download!.cancel();
            
            download = nil;
        }
        
        if html != nil
        {
            html!.cancel();
            
            html = nil;
        }
        
        if dao != nil
        {
            dao = nil;
        }
        
        setMyProgress(-666);
        
        setPlayerButton(playerStatus["toEject"]!);
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        print("PlayerViewController, viewDidDisappear");
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func initData()
    {
        itemDataFromEXT = vcBridge.Data;
    }
    
    func initView()
    {
        setMyProgress(-666);
        showMyMessage(nil);
        setDownloadButton(downloadStatus["unavailable"] ?? -1);
        setPlayerButton(playerStatus["toEject"] ?? -1);
        
        localScript = itemDataFromEXT?.Script;
        localMediaFile = itemDataFromEXT?.Media;
        
        myTitle.text = itemDataFromEXT?.Title;
        myParent.text = itemDataFromEXT?.Parent;
        myCategory.text = itemDataFromEXT?.Category ?? "";
        myPubDate.text = itemDataFromEXT?.PubDate;
        
        myScript.text = localScript ?? "";
    }

    func addObserver()
    {
        print("PlayerVC --> adding observer");
        
        observer = notice.addObserver(forName: Notification.Name(rawValue: "PlayerVC"), object: nil, queue: OperationQueue.main) { (notification) in
            
            let userInfo = notification.userInfo as! [String : Any];
            
            print("PlayerVC --> userInfo: \(userInfo)");
            
            if let message = userInfo["HtmlHandle"] as! String?
            {
                self.showMyMessage(message);
                
                self.setMyProgress(-666);
                
                self.setReloadButton(true);
                
                switch(message)
                {
                case "NOTHING_FETCHED":
                    self.showMyMessage("Unsupported Content");
                    self.setDownloadButton(self.downloadStatus["unavailable"]!);
                    break;
                case "COMPLETELY_FETCHED":
                    self.webScript = self.html!.WebScript;
                    self.webMediaLink = self.html!.WebMediaLink;
                    self.webMediaFile = self.html!.WebMediaFile;
                    
                    self.localScript = self.webScript!;
                    //self.localMediaFile = self.webMediaFile;
                    
                    self.myScript.text = self.localScript;
                    
                    self.willPlayMusicFromLink = true;
                    self.willPlayMusicFromFile = false;
                    
                    self.showMyMessage(nil);
                    self.setMyProgress(666);
                    self.setReloadButton(false);
                    
                    self.itemDataFromEXT!.Script = self.localScript!;
                    self.dao = nil;
                    self.dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "PlayerVC");
                    self.dao!.updateData(self.itemDataFromEXT!);
                    break;
                case "ONLY_MEDIA_FETCHED":
                    self.webMediaLink = self.html!.WebMediaLink;
                    self.webMediaFile = self.html!.WebMediaFile;
                    
                    if self.localScript == nil || self.localScript == ""
                    {
                        self.localScript = "No Script Provided";
                    }
                    self.localMediaFile = self.webMediaFile;
                    
                    self.myScript.text = self.localScript;
                    
                    self.willPlayMusicFromLink = true;
                    self.willPlayMusicFromFile = false;
                    
                    self.showMyMessage(nil);
                    self.setMyProgress(666);
                    self.setReloadButton(false);
                    
                    if !self.initOnlineMusicPlayer(url: self.webMediaLink!)
                    {
                        self.view.makeToast("player error", duration: 1.0, position: .bottom, title: nil, image: nil, style: ToastStyle.init(), completion: nil);
        
                    }
                    break;
                case "ONLY_SCRIPT_FETCHED":
                    self.webScript = self.html!.WebScript!;
                    self.localScript = self.webScript!;
                    
                    self.myScript.text = self.localScript;
                    
                    self.willPlayMusicFromLink = false;
                    self.willPlayMusicFromFile = false;
                    
                    self.showMyMessage("Only Script Available");
                    self.setMyProgress(666);
                    self.setReloadButton(false);
                    
                    self.itemDataFromEXT!.Script = self.localScript!;
                    self.dao = nil;
                    self.dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "PlayerVC");
                    self.dao!.updateData(self.itemDataFromEXT!);
                    break;
                default:
                    break;
                }
            }
            else if let message = userInfo["DaoHandle"] as! String?
            {
                self.showMyMessage(message);
                
                self.setMyProgress(-666);
                
                switch(message)
                {
                case "UPDATED", "INSERTED_INSTEAD":
                    if self.willPlayMusicFromLink!
                    {
                        print("PlayerVC --> on-line: \(self.webMediaLink!)");
                        
                        self.showMyMessage("initialising");
                        
                        self.setDownloadButton(self.downloadStatus["downloadable"] ?? -1);
                        
                        self.setPlayerButton(self.playerStatus["toInsert"] ?? -1);
                        
                        self.setReloadButton(true);
                        
                        self.delMusicPlayer();
                        
                        if !self.initOnlineMusicPlayer(url: self.webMediaLink!)
                        {
                            self.view.makeToast("player error", duration: 1.0, position: .bottom, title: nil, image: nil, style: ToastStyle.init(), completion: nil);
                        }
                    }
                    else if self.willPlayMusicFromFile!
                    {
                        print("PlayerVC --> off-line: \(self.localMediaFile!)");
                        
                        self.showMyMessage("initialising");
                        
                        self.setDownloadButton(self.downloadStatus["downloaded"] ?? -1);
                        
                        self.setPlayerButton(self.playerStatus["toInsert"] ?? -1);
                        
                        self.setReloadButton(true);
                        
                        self.delMusicPlayer();
                        
                        if !self.initOfflineMusicPlayer(file: self.localMediaFile!)
                        {
                            if !self.initOnlineMusicPlayer(url: self.webMediaLink!)
                            {
                                self.view.makeToast("player error", duration: 1.0, position: .bottom, title: nil, image: nil, style: ToastStyle.init(), completion: nil);
                            }
                        }
                    }
                    else
                    {
                        print("PlayerVC --> idle...");
                        
                        self.showMyMessage("Unavailable");
                        
                        self.setDownloadButton(self.downloadStatus["unavailable"] ?? -1);
                        
                        self.setReloadButton(true);
                    }
                    break;
                default:
                    break;
                }
            }
            else if let message = userInfo["Download_Message"] as! String?
            {
                self.showMyMessage(nil);
                self.setMyProgress(-666);
                
                switch(message)
                {
                case "DOWNLOADED_AND_SAVED":
                    self.setDownloadButton(self.downloadStatus["downloaded"]!);
                    //self.setPlayerButton(self.playerStatus["toPlay"]!);
                    self.localMediaFile = self.webMediaFile;
                    self.willPlayMusicFromFile = true;
                    self.willPlayMusicFromLink = false;
                    self.setMyProgress(666);
                    self.itemDataFromEXT!.Media = self.localMediaFile;
                    self.dao = nil
                    self.dao = DaoHandle(Table: DaoHandle.ITEMLIST, Response: "PlayerVC");
                    self.dao!.updateData(self.itemDataFromEXT!);
                    break;
                case "DOWNLOADED_BUT_SAVE_FAILED", "DOWNLOAD_FAILED":
                    self.setDownloadButton(self.downloadStatus["downloadable"]!);
                    if self.willPlayMusicFromLink == true
                    {
                        self.setPlayerButton(self.playerStatus["toInsert"]!);
                        if !self.initOnlineMusicPlayer(url: self.webMediaLink!)
                        {
                            self.view.makeToast("player error", duration: 1.0, position: .bottom, title: nil, image: nil, style: ToastStyle.init(), completion: nil);
                        }
                    }
                    break;
                default:
                    print("PlayerVC --> Unexpected Error Happened in DownloadHandle");
                    self.setReloadButton(true);
                    self.setDownloadButton(self.downloadStatus["unavailable"] ?? -1);
                    self.setPlayerButton(self.playerStatus["toEject"] ?? -1);
                    break;
                }
            }
            else if let progress = userInfo["Download_Progress"] as! Float?
            {
                print("PlayerVC --> Downloading Progress: \(progress)");
                
                self.setMyProgress(progress);
                self.showMyMessage(nil);
            }
        }
    }

    func delObserver()
    {
        print("PlayerVC --> removing observer");
        
        if observer != nil
        {
            notice.removeObserver(observer!);
        }
    }

    func setMyProgress(_ progress: Float)
    {
         if progress > 1.0
        {
            print("PlayerVC --> progress bar is showed automatically");
            
            totalProgressWaitedSoFar = 0;
            myProgress.progress = 0.0;
            myProgress.isHidden = false;
            
            if timer == nil || timer!.isValid == false
            {
                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
                    
                    if self.myProgress.progress >= 1.0
                    {
                        self.myProgress.progress = 0.0;
                        
                        self.view.makeToast("Might be internet connection problem, please hit reload", duration: 1.0, position: .bottom, title: nil, image: nil, style: ToastStyle.init(), completion: { (bool) in
                            
                            self.setReloadButton(true);
                        });
                    }
                    else
                    {
                        self.myProgress.progress += 0.1;
                    }
                });
                
            }
            
            timer!.fire();
        }
        else if progress > 0.0
        {
            print("PlayerVC --> progress bar is showed programatically");

            if myProgress.isHidden
            {
                myProgress.isHidden = false;
            }

            self.myProgress.progress = progress;
        }
        else
        {
            print("PlayerVC --> progress bar is hidden");
            
            myProgress.progress = 0.0;
            myProgress.isHidden = true;
            
            if timer != nil && timer!.isValid == true
            {
                timer!.invalidate();
            }
            
            timer = nil;
        }
    }
    
    func showMyMessage(_ text: String?)
    {
        if text == nil || text == ""    //to hide it...
        {
            print("PlayerVC --> message label is hidden");
            
            myMessage.text = "";
            myMessage.isHidden = true;
            myMessageHeight.constant = CGFloat(0.0);
        }
        else   //to show it...
        {
            print("PlayerVC --> message label is showed: \(text!)");
            
            myMessageHeight.constant = CGFloat(40.0);
            myMessage.isHidden = false;
            myMessage.text = text;
        }
    }

    func initLoading()
    {
        /* be ware of sequential issue */
        
        if localMediaFile != nil && localMediaFile != ""    //there is somthing inside of me
        {
            showMyMessage("...initialising...");
            
            setDownloadButton(downloadStatus["downloaded"] ?? -1);
            
            setPlayerButton(playerStatus["toInsert"] ?? -1);
            
            if(!initOfflineMusicPlayer(file: localMediaFile!))
            {
                showMyMessage("...fetching...");
                setMyProgress(-666);
                
                setDownloadButton(downloadStatus["unavailable"] ?? -1);
                
                setPlayerButton(playerStatus["toEject"] ?? -1);
                
                html = nil;
                html = HtmlHandle(RssData: itemDataFromEXT!, Response: "PlayerVC");
                html!.proceed();
            }
        }
        else
        {
            showMyMessage("...fetching...");
            setMyProgress(-666);
            
            setDownloadButton(downloadStatus["unavailable"] ?? -1);
            
            setPlayerButton(playerStatus["toEject"] ?? -1);
            
            html = nil;
            html = HtmlHandle(RssData: itemDataFromEXT!, Response: "PlayerVC");
            html!.proceed();
        }
    }
    
    func reLoading()
    {
        initView();
        
        showMyMessage("...fetching...");
        setMyProgress(-666);
        
        setDownloadButton(downloadStatus["unavailable"] ?? -1);
        
        setPlayerButton(playerStatus["toEject"] ?? -1);
        
        willPlayMusicFromFile = false;
        willPlayMusicFromLink = false;
        
        html = nil;
        html = HtmlHandle(RssData: itemDataFromEXT!, Response: "PlayerVC");
        html!.proceed();
    }

    func setDownloadButton(_ status: Int)
    {
        isDownloading = false;
        isDownloaded = false;
        
        switch(status)
        {
        case downloadStatus["downloadable"]:
            myDownload.isEnabled = true;
            myDownload.setTitle("⤓", for: .normal);
            myDownload.alpha = 1.0;
            myShare.isEnabled = true;
            myShare.alpha = 1.0;
            break;
        case downloadStatus["downloading"]:
            myDownload.isEnabled = false;
            myDownload.setTitle("▼", for: .normal);
            myDownload.alpha = 1.0;
            isDownloading = true;
            myShare.isEnabled = false;
            myShare.alpha = 0.5;
            break;
        case downloadStatus["downloaded"]:
            myDownload.isEnabled = false;
            myDownload.setTitle("≚", for: .normal);
            myDownload.alpha = 1.0;
            isDownloaded = true;
            myShare.isEnabled = true;
            myShare.alpha = 1.0;
            break;
        case downloadStatus["unavailable"]:
            myDownload.isEnabled = false;
            myDownload.setTitle("⇣", for: .normal);
            myDownload.alpha = 0.5;
            myShare.isEnabled = false;
            myShare.alpha = 0.5;
            break;
        default:
            myDownload.isEnabled = false;
            myDownload.setTitle("⇣", for: .normal);
            myDownload.alpha = 0.5;
            myShare.isEnabled = false;
            myShare.alpha = 0.5;
            break;
        }
    }
    
    func setPlayerButton(_ status: Int)
    {
        switch(status)
        {
        case playerStatus["toPlay"]: //Play
            mySlider.isHidden = false;
            mySlider.isEnabled = true;
            myPlay.isEnabled = false;
            myPause.isEnabled = true;
            myStop.isEnabled = true;
            break;
        case playerStatus["toPause"]: //Pause
            mySlider.isHidden = false;
            mySlider.isEnabled = true;
            myPlay.isEnabled = true;
            myPause.isEnabled = false;
            myStop.isEnabled = true;
            break;
        case playerStatus["toStop"]: //Stop
            mySlider.isHidden = false;
            mySlider.isEnabled = false;
            myPlay.isEnabled = true;
            myPause.isEnabled = false;
            myStop.isEnabled = false;
            break;
        case playerStatus["toEject"]: //Eject
            mySlider.value = 0;
            mySlider.isHidden = true;
            mySlider.isEnabled = false;
            myPlay.isEnabled = false;
            myPause.isEnabled = false;
            myStop.isEnabled = false;
            break;
        case playerStatus["toInsert"]: //Insert
            mySlider.value = 0;
            mySlider.isHidden = false;
            mySlider.isEnabled = false;
            myPlay.isEnabled = true;
            myPause.isEnabled = false;
            myStop.isEnabled = false;
            break;
        default:
            mySlider.value = 0;
            mySlider.isHidden = true;
            mySlider.isEnabled = false;
            myPlay.isEnabled = false;
            myPause.isEnabled = false;
            myStop.isEnabled = false;
            break;
        }
    }
    
    func setReloadButton(_ enable: Bool)
    {
        if (enable)
        {
            myReload.isEnabled = true;
            myReload.alpha = 1.0;
        }
        else
        {
            myReload.isEnabled = false;
            myReload.alpha = 0.5;
        }
    }
    
    func setShareButton(_ enable: Bool)
    {
        if (enable)
        {
            myShare.isEnabled = true;
            myShare.alpha = 1.0;
        }
        else
        {
            myShare.isEnabled = false;
            myShare.alpha = 0.5;
        }
    }
    
    /*
     *
     */
    
    func initDownloader()
    {
        self.showMyMessage("...downloading...");
        
        self.setMyProgress(-666);
        
        download = nil
        download = DownloadHandle(FileLink: webMediaLink!, FileName: webMediaFile!, Response: "PlayerVC")
        download!.proceed();
    }
    
    func delDownloader()
    {
        if download != nil
        {
            download!.cancel();
            
            download = nil;
        }
    }
    
    /*
     *  https://stackoverflow.com/questions/25348877/how-to-play-a-local-video-with-swift
     */
    
    func initOfflineMusicPlayer(file: String) -> Bool
    {
        let url = URL(fileURLWithPath: "\(NSHomeDirectory())/Documents/\(file)" )   /// <-- the running environment
        
        do
        {
            let result = try url.checkResourceIsReachable();
            
            if result
            {
                delMusicPlayer();
                
                MusicPlayer(url: url);
                
                return true;
            }
        }
        catch
        {
            print("PlayerVC --> incorrect file path for Music Player");
        }
    
        return false;
    }
    
    func initOnlineMusicPlayer(url: String) -> Bool
    {
        if let url = URL(string: url)
        {
            delMusicPlayer();
            
            MusicPlayer(url: url);
            
            return true;
        }
        else
        {
            print("PlayerVC --> incorrect URL for Music Player");
        }
        
        return false;
    }
    
    func delMusicPlayer()
    {
        if player != nil
        {
            player!.removeTimeObserver(playerObserver!);
            
            player = nil;
        }
    }
    
    func MusicPlayer(url: URL)
    {
        playerItem = nil;
        player = nil
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem!)
        
        let duration : CMTime = playerItem!.asset.duration
        let seconds : Float64 = CMTimeGetSeconds(duration);
        
        showMyMessage(nil);
        
        mySlider!.value = 0;
        mySlider!.minimumValue = 0;
        mySlider!.maximumValue = Float(seconds);
        mySlider!.isContinuous = false  // <-- https://developer.apple.com/documentation/uikit/uislider/1621340-iscontinuous
        
        playerObserver = player!.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 1), queue: DispatchQueue.main) { (CMTime) in
            
            if self.player!.currentItem?.status == .readyToPlay
            {
                let seconds = CMTimeGetSeconds(self.player!.currentTime());
                let currentTime = Float(seconds);
                
                self.mySlider!.value = currentTime;
                
                if self.mySlider!.value == self.mySlider.maximumValue   //reaching end...
                {
                    self.setPlayerButton(self.playerStatus["toStop"] ?? -1);
                    
                    self.player!.pause();
                    
                    self.player!.seek(to: CMTimeMake(value: 0, timescale: 1));
                }
            }
        }
    }
}
