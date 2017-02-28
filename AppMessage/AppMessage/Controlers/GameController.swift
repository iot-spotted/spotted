//
//  GameController.swift
//  AppMessage
//
//  Created by Robert Maratos on 2/23/17.
//  Copyright © 2017 mirabeau. All rights reserved.
//

import EVCloudKitDao
import CloudKit
import EVReflection
import Async


class GameController {
    var Group_ID: String = GLOBAL_GROUP_ID
    var LocalGroupState: GroupState? = nil
    var CurrentVote: Vote
    var Voting: Bool = false
    var CurrentSender: Bool = false
    
    var parent: MainViewController
    var photoViewController : PhotoViewController?
    
    init(parentView: MainViewController) {
        parent = parentView
        CurrentVote = Vote()
        initializeCommunication()
    }
    
    func initializeCommunication(_ retryCount: Double = 1) {
        // GroupState Connection
        EVCloudData.publicDB.connect(GroupState(), predicate: NSPredicate(format: "Group_ID == '\(Group_ID)'"), filterId: "Group_ID_\(Group_ID)",
            completionHandler: { results, status in
                EVLog("GroupState results = \(results.count)")
                if results.count > 0 {
                    self.LocalGroupState = results[0]
                    print("Got LocalGroupState for \(self.LocalGroupState!.Group_ID)")
                }
                return true
        }, insertedHandler: { item in
            EVLog("GroupState inserted")
            self.LocalGroupState = item
        }, updatedHandler: { item, dataIndex in
            EVLog("GroupState updated")
            self.LocalGroupState = item
        }, deletedHandler: { recordId, dataIndex in
            EVLog("GroupState deleted!!! : \(recordId)")
            self.LocalGroupState = nil
        }, dataChangedHandler: {
            EVLog("GroupState data changed!")
        }, errorHandler: { error in
            switch EVCloudKitDao.handleCloudKitErrorAs(error, retryAttempt: retryCount) {
            case .retry(let timeToWait):
                Async.background(after: timeToWait) {
                    self.initializeCommunication(retryCount + 1)
                }
            case .fail:
                Helper.showError("Could not load groupdata: \(error.localizedDescription)")
            default: // For here there is no need to handle the .Success, and .RecoverableError
                break
            }
        });
        
        EVCloudData.publicDB.connect(Vote(), predicate: NSPredicate(format: "Group_ID == '\(Group_ID)'"), filterId: "Vote_Group_ID_\(Group_ID)",
            completionHandler: { results, status in
                EVLog("Vote results = \(results.count)")
                if results.count > 0 {
                    // TODO check for in progress votes
                }
                return true
        }, insertedHandler: { item in
            EVLog("VOTE inserted " + item.recordID.recordName)
            self.CurrentVote = item
            self.Voting = true
            // Only start UI if not current sender
            if (!self.CurrentSender) {
                self.StartVoteUI(vote: item)
            }
        }, updatedHandler: { item, dataIndex in
            EVLog("VOTE updated " + item.recordID.recordName)
            // TODO make sure it's the  same vote

            if (self.Voting) {
                self.CurrentVote = item
                print("VOTE in voting state...calling update")
                
                // SET VOTE TO FALSE
                if self.CurrentVote.Status != VoteStatusEnum.InProgress.rawValue  {
                    self.Voting = false
                    self.CurrentSender = false
                }
                self.UpdateUI()
            } else {
                print("VOTE not in voting mode, ignoring")
            }
        }, deletedHandler: { recordId, dataIndex in
            EVLog("VOTE deleted!!! : \(recordId)")
            self.LocalGroupState = nil
        }, dataChangedHandler: {
            EVLog("VOTE data changed!")
        }, errorHandler: { error in
            switch EVCloudKitDao.handleCloudKitErrorAs(error, retryAttempt: retryCount) {
            case .retry(let timeToWait):
                Async.background(after: timeToWait) {
                    self.initializeCommunication(retryCount + 1)
                }
            case .fail:
                Helper.showError("Could not load groupdata: \(error.localizedDescription)")
            default: // For here there is no need to handle the .Success, and .RecoverableError
                break
            }
        });
    }
    
    
    // UNUSED
    func GetItUser() {
        EVCloudData.publicDB.dao.query(GameUser(), predicate: NSPredicate(format: "User_Id == '\(LocalGroupState!.It_User_ID)'"),
            completionHandler: { results, stats in
            EVLog("query : result count = \(results.count)")
            if (results.count >= 0) {
                print("It_User=\(self.LocalGroupState?.It_Name ?? "")!")
                self.parent.cameraViewController?.updateLabel(label: (self.LocalGroupState?.It_Name)!)
            }
            return true
        }, errorHandler: { error in
            EVLog("<--- ERROR query User")
        })
    }
    

    func ChangeItUser() {
        self.LocalGroupState?.It_User_ID = CurrentVote.Sender_User_ID
        self.LocalGroupState?.It_Name = CurrentVote.Sender_Name
        
        SendMessage("Accepted! (\(CurrentVote.Yes) - \(CurrentVote.No)) \(CurrentVote.Sender_Name) now it!")
        print("setting user to senderrecordID")
        EVCloudData.publicDB.saveItem(self.LocalGroupState!, completionHandler: {record in
            let createdId = record.recordID.recordName;
            EVLog("saveItem : \(createdId)");
        }, errorHandler: {error in
            EVLog("<--- ERROR saveItem");
        })
    }
    
    func StartVote(Sender_User_ID: String, Sender_Name: String, Asset_ID: String) {
        print("starting vote")
        self.CurrentSender = true
        self.Voting = true
        CurrentVote = Vote()
        CurrentVote.Group_ID = Group_ID
        CurrentVote.It_User_ID = LocalGroupState!.It_User_ID
        CurrentVote.Sender_User_ID = Sender_User_ID
        CurrentVote.Sender_Name = Sender_Name
        CurrentVote.Asset_ID = Asset_ID
        SaveVote()
    }
    
    func StartVoteUI(vote: Vote) {
        print("StartVoteUI")
        self.photoViewController = UIStoryboard(name: "Storyboard", bundle: nil).instantiateViewController(withIdentifier: "photoViewController") as? PhotoViewController

        self.photoViewController?.mode = Mode.Receiver
        self.photoViewController?.gameController = self
        self.photoViewController?.itValue = self.LocalGroupState?.It_Name
        EVCloudData.publicDB.getItem(vote.Asset_ID, completionHandler: {item in
            if let asset = item as? Asset {
                self.photoViewController?.image = asset.File?.image()
            }
            self.parent.present(self.photoViewController!, animated: true, completion: nil)
        }, errorHandler: { error in
            Helper.showError("Could not load Asset: \(error.localizedDescription)")
            self.parent.present(self.photoViewController!, animated: true, completion: nil)
        })
    }
    
    func UpdateUI() {
        print("updating ui...")
        if let controller = self.photoViewController {
            controller.UpdateUI(self.CurrentVote)
        } else{
            print("controller is nil")
        }
    }
    
    func VoteYes() {
        print("voting yes")
        CurrentVote.Yes += 1
        if CurrentVote.Yes == 2 {
            CurrentVote.Status = VoteStatusEnum.Pass.rawValue
            ChangeItUser()
        }
        self.photoViewController?.yes.text = String(CurrentVote.Yes)
        SaveVote()
        Voting = false
    }
    
    func VoteNo()  {
        print("voting no")
        CurrentVote.No += 1
        if CurrentVote.No == 2 {
            CurrentVote.Status = VoteStatusEnum.Fail.rawValue
            SendMessage("Rejected! (\(CurrentVote.Yes) - \(CurrentVote.No))")
        }
        self.photoViewController?.no.text = String(CurrentVote.No)
        SaveVote()
        Voting = false
    }
    
    func SaveVote() {
        EVCloudData.publicDB.saveItem(CurrentVote, completionHandler: {record in
            let createdId = record.recordID.recordName;
            EVLog("vote saveItem : \(createdId)");
            NSLog(" voted")
        }, errorHandler: {error in
            EVLog("<--- ERROR saveItem");
        })
    }
    
    func SendMessage(_ text: String) {
        let message = Message()
        message.FromFirstName = "bot"
        message.FromLastName = ""
        message.setToFields(GLOBAL_GROUP_ID)
        message.GroupChatName = GLOBAL_GROUP_NAME
        message.Text = text
        EVCloudData.publicDB.saveItem(message, completionHandler: { message in
            //self.finishSendingMessage()
        }, errorHandler: { error in
            //self.finishSendingMessage()
            Helper.showError("Could not send message!  \(error.localizedDescription)")
        })
        //self.finishSendingMessage()
    }

}
