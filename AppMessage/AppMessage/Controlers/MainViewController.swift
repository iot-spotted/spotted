//
//  MainViewController.swift
//  AppMessage
//
//  Created by Jake Weiss on 2/21/17.
//  Copyright © 2017 mirabeau. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    @IBOutlet var scrollView: UIScrollView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let homeViewController: HomeViewController = HomeViewController(nibName: "homeViewController", bundle: nil)
//        let chatViewController: ChatViewController = ChatViewController(nibName: "chatViewController", bundle: nil)
        let homeViewController:HomeViewController = UIStoryboard(name: "Storyboard", bundle: nil).instantiateViewController(withIdentifier: "homeViewController") as! HomeViewController
        let chatViewController:ChatViewController = UIStoryboard(name: "Storyboard", bundle: nil).instantiateViewController(withIdentifier: "chatViewController") as! ChatViewController
        
        self.addChildViewController(chatViewController)
        self.scrollView!.addSubview(chatViewController.view)
        chatViewController.didMove(toParentViewController: self)
        
        self.addChildViewController(homeViewController)
        self.scrollView!.addSubview(homeViewController.view)
        homeViewController.didMove(toParentViewController: self)
        
        var mainFrame :CGRect = homeViewController.view.frame;
        mainFrame.origin.x = mainFrame.width;
        chatViewController.view.frame = mainFrame;
        
        var chatFrame :CGRect = chatViewController.view.frame;
        chatFrame.origin.x = 2*chatFrame.width;
        //CVc.view.frame = BFrame;
        
        var scrollWidth: CGFloat  = 3 * self.view.frame.width
        var scrollHeight: CGFloat  = self.view.frame.size.height
        self.scrollView!.contentSize = CGSize(width: scrollWidth, height: scrollHeight);
    }
}
