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
        
        self.createGameUserIfNotExists()
        self.gameController = GameController(parentView: self)
        self.cameraViewController?.gameController = self.gameController
        self.chatViewController?.gameController = self.gameController
        
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
        
        self.registerForMessageNotifications()
        self.registerForVoteNotifications()
        self.registerForItNotifications()
        
    }

    func createGameUserIfNotExists() {
        
        let recordIdMe = getMyRecordID()
        
        EVCloudData.publicDB.dao.query(GameUser(), predicate: NSPredicate(format: "User_ID == '\(recordIdMe)'"),
           completionHandler: { results, stats in
            EVLog("query : result count = \(results.count)")
            if (results.count == 0) {
                print("creating user...")
                let user = GameUser()
                user.User_ID = recordIdMe
                user.Name = getMyName()
                
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
                
        EVCloudData.publicDB.dao.query(GroupState(), predicate: NSPredicate(format: "Group_ID == '\(GLOBAL_GROUP_ID)'"),
           completionHandler: { results, stats in
            EVLog("query : result count = \(results.count)")
            if (results.count == 0) {
                print("group does not exist")
                let group = GroupState()
                
                group.Group_ID = GLOBAL_GROUP_ID
                group.It_User_ID = recordIdMe
                group.It_User_Name = getMyName()
                
                EVCloudData.publicDB.saveItem(group, completionHandler: {group in
                    print("Created group")
                    print(group)
                }, errorHandler: { error in
                    Helper.showError("Could not create group!  \(error.localizedDescription)")
                })
            } else {
                print("group already exists");
            }
            return true
        }
        );
        
    }
    
    func registerForMessageNotifications(_ retryCount: Double = 1) {
        EVCloudData.publicDB.connect(Message(), predicate: NSPredicate(format: "To_ID = %@", GLOBAL_GROUP_ID), filterId: "Message_ToGroup", configureNotificationInfo: { notificationInfo in
            notificationInfo.alertLocalizationKey = "%1$@ %2$@ : %3$@"
            notificationInfo.alertLocalizationArgs = ["FromFirstName", "FromLastName", "Text"]
        }, completionHandler: { results, status in
            EVLog("Message to group results = \(results.count)")
            return status == CompletionStatus.partialResult && results.count < 200 // Continue reading if we have less than 200 records and if there are more.
        }, insertedHandler: { item in
            EVLog("Message to group inserted \(item)")
            //self.startChat(item.From_ID, firstName: item.ToFirstName, lastName: item.ToLastName)
            //self.createGameUserIfNotExists()
            //self.scrollView!.contentOffset = CGPoint(x:self.view.frame.width*2,y:0)
        }, updatedHandler: { item, dataIndex in
            EVLog("Message to group updated \(item)")
        }, deletedHandler: { recordId, dataIndex in
            EVLog("Message to group deleted : \(recordId)")
        }, errorHandler: { error in
            switch EVCloudKitDao.handleCloudKitErrorAs(error, retryAttempt: retryCount) {
            case .retry(let timeToWait):
                Helper.showError("Could not load messages: \(error.localizedDescription)")
                Async.background(after: timeToWait) {
                    self.registerForMessageNotifications(retryCount + 1)
                }
            case .fail:
                Helper.showError("Could not load messages: \(error.localizedDescription)")
            default: // For here there is no need to handle the .Success and .RecoverableError
                break
            }
            
        })
    }
    
    func registerForVoteNotifications(_ retryCount: Double = 1) {
        EVCloudData.publicDB.connect(Vote(), predicate: NSPredicate(format: "Group_ID = %@ AND Status == 'I'", GLOBAL_GROUP_ID), filterId: "Vote_ToGroup", configureNotificationInfo: { notificationInfo in
            notificationInfo.alertLocalizationKey = "Verify %1$@'s photo of %2$@!"
            notificationInfo.alertLocalizationArgs = ["Sender_Name", "It_User_Name"]
        }, completionHandler: { results, status in
            EVLog("Vote to group results = \(results.count)")
            return status == CompletionStatus.partialResult && results.count < 200 // Continue reading if we have less than 200 records and if there are more.
        }, insertedHandler: { item in
            EVLog("Vote to group inserted \(item)")
        }, updatedHandler: { item, dataIndex in
            EVLog("Vote to group updated \(item)")
        }, deletedHandler: { recordId, dataIndex in
            EVLog("Vote to group deleted : \(recordId)")
        }, errorHandler: { error in
            switch EVCloudKitDao.handleCloudKitErrorAs(error, retryAttempt: retryCount) {
            case .retry(let timeToWait):
                Helper.showError("Could not load vote: \(error.localizedDescription)")
                Async.background(after: timeToWait) {
                    self.registerForVoteNotifications(retryCount + 1)
                }
            case .fail:
                Helper.showError("Could not load vote: \(error.localizedDescription)")
            default: // For here there is no need to handle the .Success and .RecoverableError
                break
            }
            
        })
    }
    
    func registerForItNotifications(_ retryCount: Double = 1) {
        EVCloudData.publicDB.connect(GroupState(), predicate: NSPredicate(format: "Group_ID = %@", GLOBAL_GROUP_ID), filterId: "It_Changed", configureNotificationInfo: { notificationInfo in
            notificationInfo.alertLocalizationKey = "%1$@ is now It!"
            notificationInfo.alertLocalizationArgs = ["It_User_Name"]
        }, completionHandler: { results, status in
            EVLog("It results = \(results.count)")
            return status == CompletionStatus.partialResult && results.count < 200 // Continue reading if we have less than 200 records and if there are more.
        }, insertedHandler: { item in
            EVLog("It inserted \(item)")
        }, updatedHandler: { item, dataIndex in
            EVLog("It updated \(item)")
        }, deletedHandler: { recordId, dataIndex in
            EVLog("It deleted : \(recordId)")
        }, errorHandler: { error in
            switch EVCloudKitDao.handleCloudKitErrorAs(error, retryAttempt: retryCount) {
            case .retry(let timeToWait):
                Helper.showError("Could not load it change: \(error.localizedDescription)")
                Async.background(after: timeToWait) {
                    self.registerForItNotifications(retryCount + 1)
                }
            case .fail:
                Helper.showError("Could not load it change: \(error.localizedDescription)")
            default: // For here there is no need to handle the .Success and .RecoverableError
                break
            }
            
        })
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
