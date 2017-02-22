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
    
    var homeViewController: HomeViewController?
    var chatViewController: ChatViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(forName:Notification.Name(rawValue:"loadChat"),
                                                     object:nil, queue:nil,
                                                     using:loadChat)
        
        
        
        self.homeViewController = UIStoryboard(name: "Storyboard", bundle: nil).instantiateViewController(withIdentifier: "homeViewController") as! HomeViewController
        self.chatViewController = UIStoryboard(name: "Storyboard", bundle: nil).instantiateViewController(withIdentifier: "chatViewController") as! ChatViewController
        
        self.chatViewController?.setContact("", fakeGroupChatName: "lol")
        
        self.addChildViewController(self.chatViewController!)
        self.scrollView!.addSubview((self.chatViewController?.view)!)
        self.chatViewController?.didMove(toParentViewController: self)
        
        self.addChildViewController(self.homeViewController!)
        self.scrollView!.addSubview((self.homeViewController?.view)!)
        self.homeViewController?.didMove(toParentViewController: self)
        
        var mainFrame :CGRect = self.homeViewController!.view.frame;
        mainFrame.origin.x = mainFrame.width;
        self.chatViewController?.view.frame = mainFrame;
        
        var chatFrame :CGRect = self.chatViewController!.view.frame;
        chatFrame.origin.x = 2*chatFrame.width;
        //CVc.view.frame = BFrame;
        
        let scrollWidth: CGFloat  = 2 * self.view.frame.width
        let scrollHeight: CGFloat  = self.view.frame.size.height
        self.scrollView!.contentSize = CGSize(width: scrollWidth, height: scrollHeight);
    }
    
    func loadChat(notification: Notification) {
        self.scrollView!.scrollRectToVisible(CGRect(x:(self.homeViewController?.view.frame.width)!,y:0,width:(self.chatViewController?.view.frame.width)!,height:(self.chatViewController?.view.frame.height)!), animated: true)
    }

}
