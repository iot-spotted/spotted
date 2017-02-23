//
//  MainViewController.swift
//  AppMessage
//
//  Created by Jake Weiss on 2/21/17.
//  Copyright © 2017 mirabeau. All rights reserved.
//

import UIKit
import EVCloudKitDao
import CloudKit
import Async

class MainViewController: UIViewController {
    
    @IBOutlet var scrollView: UIScrollView?
    
    var cameraViewController: CameraViewController?
    var chatViewController: ChatViewController?
    var profileViewController: ProfileViewController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(forName:Notification.Name(rawValue:"loadChat"),
                                                     object:nil, queue:nil,
                                                     using:loadChat)
        NotificationCenter.default.addObserver(forName:Notification.Name(rawValue:"loadCamera"),
                                               object:nil, queue:nil,
                                               using:loadCamera)
        
        
        
        self.profileViewController = UIStoryboard(name: "Storyboard", bundle: nil).instantiateViewController(withIdentifier: "profileViewController") as! ProfileViewController
        self.cameraViewController = UIStoryboard(name: "Storyboard", bundle: nil).instantiateViewController(withIdentifier: "cameraViewController") as! CameraViewController
        self.chatViewController = UIStoryboard(name: "Storyboard", bundle: nil).instantiateViewController(withIdentifier: "chatViewController") as! ChatViewController
        self.chatViewController?.setContact("", fakeGroupChatName: "lol")
                
        
        self.addChildViewController(self.chatViewController!)
        self.scrollView!.addSubview((self.chatViewController?.view)!)
        self.chatViewController?.didMove(toParentViewController: self)
        
        self.addChildViewController(self.cameraViewController!)
        self.scrollView!.addSubview((self.cameraViewController?.view)!)
        self.cameraViewController?.didMove(toParentViewController: self)
        
        self.addChildViewController(self.profileViewController!)
        self.scrollView!.addSubview((self.profileViewController?.view)!)
        self.profileViewController?.didMove(toParentViewController: self)
        
        var frame :CGRect = UIScreen.main.bounds
        frame.origin.x = frame.width
        self.cameraViewController?.view.frame = frame
        
        frame.origin.x = 2*frame.width;
        self.chatViewController?.view.frame = frame;
        
        let scrollWidth: CGFloat  = 3 * frame.width
        let scrollHeight: CGFloat  = frame.height
        self.scrollView!.contentSize = CGSize(width: scrollWidth, height: scrollHeight);
        self.scrollView!.keyboardDismissMode = .onDrag
        
        self.scrollView!.scrollRectToVisible(CGRect(x:frame.width,y:0,width:frame.width,height:frame.height), animated: true)
    }
    
    func loadChat(notification: Notification) {
        self.scrollView!.scrollRectToVisible(CGRect(x:(self.cameraViewController?.view.frame.width)!,y:0,width:(self.chatViewController?.view.frame.width)!,height:(self.chatViewController?.view.frame.height)!), animated: true)
    }
    func loadCamera(notification: Notification) {
        self.scrollView!.scrollRectToVisible(CGRect(x:0,y:0,width:(self.cameraViewController?.view.frame.width)!,height:(self.cameraViewController?.view.frame.height)!), animated: true)
    }

}
