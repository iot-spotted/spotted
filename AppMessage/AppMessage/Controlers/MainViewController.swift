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
    var gameController: GameController? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(forName:Notification.Name(rawValue:"loadChat"),
                                                     object:nil, queue:nil,
                                                     using:loadChat)
        NotificationCenter.default.addObserver(forName:Notification.Name(rawValue:"loadCamera"),
                                               object:nil, queue:nil,
                                               using:loadCamera)
        NotificationCenter.default.addObserver(forName:Notification.Name(rawValue:"loadProfile"),
                                               object:nil, queue:nil,
                                               using:loadProfile)
       
        self.profileViewController = UIStoryboard(name: "Storyboard", bundle: nil).instantiateViewController(withIdentifier: "profileViewController") as! ProfileViewController
        self.cameraViewController = UIStoryboard(name: "Storyboard", bundle: nil).instantiateViewController(withIdentifier: "cameraViewController") as! CameraViewController
        self.chatViewController = UIStoryboard(name: "Storyboard", bundle: nil).instantiateViewController(withIdentifier: "chatViewController") as! ChatViewController
        
        self.gameController = GameController(parentView: self)
        self.cameraViewController?.gameController = self.gameController
        
        
        self.chatViewController?.setContact("", fakeGroupChatName: "lol")
        
        self.addChildViewController(self.cameraViewController!)
        self.scrollView!.addSubview((self.cameraViewController?.view)!)
        self.cameraViewController?.didMove(toParentViewController: self)
        
        self.addChildViewController(self.profileViewController!)
        self.scrollView!.addSubview((self.profileViewController?.view)!)
        self.profileViewController?.didMove(toParentViewController: self)
    
        
        self.addChildViewController(self.chatViewController!)
        self.scrollView!.addSubview((self.chatViewController?.view)!)
        self.chatViewController?.didMove(toParentViewController: self)
        
        
        var profileFrame :CGRect = self.profileViewController!.view.frame
        profileFrame.origin.x = profileFrame.width
        self.cameraViewController?.view.frame = profileFrame
        
        var cameraFrame :CGRect = self.cameraViewController!.view.frame
        cameraFrame.origin.x = 2*cameraFrame.width;
        self.chatViewController?.view.frame = cameraFrame;
        
        let scrollWidth: CGFloat  = 3 * self.view.frame.width
        let scrollHeight: CGFloat  = self.view.frame.height
        self.scrollView!.contentSize = CGSize(width: scrollWidth, height: scrollHeight);
        self.scrollView!.keyboardDismissMode = .onDrag
        
        self.scrollView!.contentOffset = CGPoint(x:self.view.frame.width,y:0)
        
    }
    
    func createGameUserIfNotExists() {
        
        var recordIdMe: String
        if #available(iOS 10.0, *) {
            recordIdMe = (EVCloudData.publicDB.dao.activeUser as? CKUserIdentity)?.userRecordID?.recordName ?? "42"
        } else {
            recordIdMe = (EVCloudData.publicDB.dao.activeUser as? CKDiscoveredUserInfo)?.userRecordID?.recordName ?? "42"
        }
        
        func GetItUser() {
            EVCloudData.publicDB.dao.query(GameUser(), predicate: NSPredicate(format: "User_Id == '\(recordIdMe)'"),
                                           completionHandler: { results, stats in
                                            EVLog("query : result count = \(results.count)")
                                            if (results.count == 0) {
                                                print("creating user...")
                                                let user = GameUser()
                                                user.User_Id = recordIdMe
                                                
                                                if #available(iOS 10.0, *) {
                                                    user.UserFirstName = (EVCloudData.publicDB.dao.activeUser as? CKUserIdentity)?.nameComponents?.givenName ?? ""
                                                    user.UserLastName = (EVCloudData.publicDB.dao.activeUser as? CKUserIdentity)?.nameComponents?.familyName ?? ""
                                                } else {
                                                    user.UserLastName = (EVCloudData.publicDB.dao.activeUser as? CKDiscoveredUserInfo)?.firstName ?? ""
                                                    user.UserLastName = (EVCloudData.publicDB.dao.activeUser as? CKDiscoveredUserInfo)?.lastName ?? ""
                                                }
                                                
                                                EVCloudData.publicDB.saveItem(user, completionHandler: {user in
                                                    print("Created user")
                                                    print(user)
                                                }, errorHandler: {error in
                                                    Helper.showError("Could not create group!  \(error.localizedDescription)")
                                                })
                                        }
                                            return true
            }, errorHandler: { error in
                EVLog("<--- ERROR query User")
            })
        }

    }
    
    override func viewDidLayoutSubviews() {
        profileViewController?.view.frame = self.view.frame
    }
    
    func loadChat(notification: Notification) {
        self.scrollView!.scrollRectToVisible(CGRect(x:(self.chatViewController?.view.frame.origin.x)!,y:0,width:(self.chatViewController?.view.frame.width)!,height:(self.chatViewController?.view.frame.height)!), animated: true)
    }
    func loadCamera(notification: Notification) {
        self.scrollView!.scrollRectToVisible(CGRect(x:(self.cameraViewController?.view.frame.origin.x)!,y:0,width:(self.cameraViewController?.view.frame.origin.x)!,height:(self.cameraViewController?.view.frame.height)!), animated: true)
    }
    func loadProfile(notification: Notification) {
        self.scrollView!.scrollRectToVisible(CGRect(x:0,y:0,width:(self.profileViewController?.view.frame.width)!,height:(self.profileViewController?.view.frame.height)!), animated: true)
    }

}
