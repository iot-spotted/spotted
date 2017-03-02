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
    var myRecordID: String = getMyRecordID()
    var LocalGroupState: GroupState!
    var CurrentVote: Vote
    var Voting: Bool = false
    var CurrentSender: Bool = false
    var LastVote: Bool?

    
    var parent: MainViewController
    var photoViewController : PhotoViewController?
    
    init(parentView: MainViewController) {
        parent = parentView
        CurrentVote = Vote()
        initializeCommunication()
    }
    
    // Initialize CloudKit Handlers
    func initializeCommunication(_ retryCount: Double = 1) {
        // GroupState Connection
        EVCloudData.publicDB.connect(GroupState(), predicate: NSPredicate(format: "Group_ID == '\(Group_ID)'"), filterId: "Group_ID_\(Group_ID)",
            completionHandler: { results, status in
                if results.count > 0 {
                    self.LocalGroupState = results[0]
                    self.parent.cameraViewController?.updateLabel(label: (self.LocalGroupState?.It_User_Name)!)
                    print("LocalGroupState set for \(self.LocalGroupState!.Group_ID)")
                }
                return true
        }, insertedHandler: { item in
            EVLog("GroupState inserted")
            self.LocalGroupState = item
        }, updatedHandler: { item, dataIndex in
            EVLog("GroupState updated")
            self.LocalGroupState = item
            if let v = self.LastVote {
                if (v) {
                    print("Voted yes correctly, incrementing score")
                    self.IncrementScore(CORRECT_VOTE_SCORE)
                } else {
                    print("Voted no incorrectly, decrementing score")
                    self.IncrementScore(INCORRECT_VOTE_SCORE)
                }
                self.LastVote = nil
            }

            if self.Voting {
                self.Voting = false
                self.CurrentVote.Status = VoteStatusEnum.Pass.rawValue
                self.UpdateUI()
            }
            self.parent.cameraViewController?.updateLabel(label: (self.LocalGroupState?.It_User_Name)!)
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
                // TODO check for in progress votes
                return true
        }, insertedHandler: { item in
            EVLog("VOTE inserted " + item.recordID.recordName)
            if (self.Voting) {
                return
            }
            self.CurrentVote = item
            self.Voting = true
            self.LastVote = nil
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

                if self.CurrentVote.Status == VoteStatusEnum.Fail.rawValue {
                    if let v = self.LastVote {
                        if (v) {
                            print("Voted no correctly, incrementing score")
                            self.IncrementScore(INCORRECT_VOTE_SCORE)
                        } else {
                            print("Voted yes incorrectly, decrementing score")
                            self.IncrementScore(CORRECT_VOTE_SCORE)
                        }

                    }
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
        
        EVCloudData.publicDB.connect(UserVote(), predicate: NSPredicate(value: true), filterId: "User_Vote_ALL",
            completionHandler: { results, status in
                // TODO check for in progress votes
                return true
        }, insertedHandler: { item in
            EVLog("USER VOTE inserted " + item.recordID.recordName)
            self.HandleNewUserVote(vote: item)
        }, updatedHandler: { item, dataIndex in
            EVLog("USER VOTE updated (shouldn't happen)" + item.recordID.recordName)
        }, deletedHandler: { recordId, dataIndex in
            EVLog("USER VOTE deleted!!! : \(recordId)")
            self.LocalGroupState = nil
        }, dataChangedHandler: {
            EVLog("USER VOTE data changed!")
        }, errorHandler: { error in
            print("USER VOTE ERROR")
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

    // Initialize vote object to send to cloud
    func StartVote(Sender_User_ID: String, Sender_Name: String, Asset_ID: String) {
        print("starting vote")
        self.CurrentSender = true
        self.Voting = true
        CurrentVote = Vote()
        CurrentVote.Group_ID = Group_ID
        CurrentVote.It_User_ID = LocalGroupState!.It_User_ID
        CurrentVote.It_User_Name = LocalGroupState!.It_User_Name
        CurrentVote.Sender_User_ID = Sender_User_ID
        CurrentVote.Sender_Name = Sender_Name
        CurrentVote.Asset_ID = Asset_ID
//        var gameTimer: Timer!
//        gameTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(GetUserVotes), userInfo: nil, repeats: true)
        SaveVote()
    }
    
    // Popup Vote UI
    func StartVoteUI(vote: Vote) {
        print("StartVoteUI")
        self.photoViewController = UIStoryboard(name: "Storyboard", bundle: nil).instantiateViewController(withIdentifier: "photoViewController") as? PhotoViewController

        if (vote.It_User_ID == myRecordID) {
            self.photoViewController?.mode = Mode.ItUser
        } else {
            self.photoViewController?.mode = Mode.Receiver
        }
        self.photoViewController?.gameController = self
        self.photoViewController?.itValue = self.LocalGroupState?.It_User_Name
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
    
    // Send updated vote to photo controller
    func UpdateUI() {
        print("UpdateUI...")
        if let controller = self.photoViewController {
            controller.UpdateUI(self.CurrentVote)
        } else{
            print("controller is nil")
        }
    }
    
    // Vote Yes and end vote if done
    func VoteYes() {
        print("VoteYes")
        LastVote = true
        Voting = false
        SaveUserVote(Yes: true)
    }
    
    // Vote No and reject if done
    func VoteNo()  {
        print("VoteNo")
        LastVote = false
        Voting = false
        SaveUserVote(Yes: false)
    }
    
    func SaveUserVote(Yes: Bool) {
        let vote = UserVote()
        vote.Vote_ID = CurrentVote.recordID.recordName
        vote.Yes = Yes
        
        EVCloudData.publicDB.saveItem(vote, completionHandler: {record in
            let createdId = record.recordID.recordName;
            EVLog("SaveUserVote saveItem : \(createdId)");
        }, errorHandler: {error in
            EVLog("<--- ERROR saveItem");
        })
    }
    
    func HandleNewUserVote(vote: UserVote) {
        if ((vote.Vote_ID == CurrentVote.recordID.recordName) && (vote.User_ID != myRecordID)) {
            print("HandleNewUserVote Got valid vote update")
            if (vote.Yes) {
                CurrentVote.Yes += 1
            } else {
                CurrentVote.No += 1
            }
            
            if (self.CurrentSender) {
                if CurrentVote.Yes == YES_VOTE_LIMIT {
                    print("Vote yes at limit, done")
                    CurrentVote.Status = VoteStatusEnum.Pass.rawValue
                    self.Voting = false
                    self.CurrentSender = false
                    ChangeItUser()
                    self.IncrementScore(BECOMING_IT_SCORE)
                    self.SendPic(CurrentVote.Asset_ID)
                }
                if CurrentVote.No == NO_VOTE_LIMIT {
                    print("Vote no at limit")
                    CurrentVote.Status = VoteStatusEnum.Fail.rawValue
                    self.Voting = false
                    self.CurrentSender = false
                    SaveVote()
                }

            }
            self.UpdateUI()
        } else {
            print("Bad vote id \(vote.Vote_ID) != \(CurrentVote.recordID.recordName) or \(vote.User_ID) == \(myRecordID)")
        }
    }
    // Cancel vote and set to failed
    func CancelVote() {
        print("CancelVote...")
        Voting = false
        CurrentSender = false
        CurrentVote.Status = VoteStatusEnum.Fail.rawValue
        SaveVote()
    }
    
    // Save updated vote to cloud
    func SaveVote() {
        EVCloudData.publicDB.saveItem(CurrentVote, completionHandler: {record in
            let createdId = record.recordID.recordName;
            self.CurrentVote = record
            EVLog("SaveVote saveItem : \(createdId)");
        }, errorHandler: {error in
            EVLog("<--- ERROR saveItem");
        })
    }
    
    // Change it user on cloud and send message
    func ChangeItUser() {
        self.LocalGroupState?.It_User_ID = CurrentVote.Sender_User_ID
        self.LocalGroupState?.It_User_Name = CurrentVote.Sender_Name
        self.parent.cameraViewController?.updateLabel(label: (self.LocalGroupState?.It_User_Name)!)
        
        print("ChangeItUser setting user to ItUser")
        EVCloudData.publicDB.saveItem(self.LocalGroupState!, completionHandler: {record in
            let createdId = record.recordID.recordName;
            EVLog("ChangeItUser Changed: \(createdId)");
        }, errorHandler: {error in
            EVLog("<--- ERROR saveItem");
        })
    }
    
    // Increment score for user
    func IncrementScore(_ amount: Int) {
        print("IncrementScore by " + String(amount))
        EVCloudData.publicDB.dao.query(GameUser(), predicate: NSPredicate(format: "User_ID == '\(myRecordID)'"),
           completionHandler: { results, stats in
            print("IncrementScore Updating user score...")
            let user = results[0]
            user.Score += amount
            
            EVCloudData.publicDB.saveItem(user, completionHandler: {user in
                print("IncrementScore Updated user score")
                print(user)
            }, errorHandler: {error in
                Helper.showError("IncrementScore Could not update score!  \(error.localizedDescription)")
            })
            return true
        }, errorHandler: { error in
            EVLog("<--- ERROR query User")
        })
    }
    
    @objc func GetUserVotes() {
        EVCloudData.publicDB.dao.query(UserVote(), predicate: NSPredicate(format: "Vote_ID == '\(CurrentVote.recordID.recordName)'"),
           completionHandler: { results, stats in
            print("Got some UserVotes...")
            var no = 0
            var yes = 0

            for vote in results {
                if vote.Yes {
                    yes += 1
                } else {
                    no += 1
                }
            }
            print("Updating yes from \(self.CurrentVote.Yes) to \(yes)")
            print("Updating no from \(self.CurrentVote.No) to \(no)")

            self.CurrentVote.Yes = yes
            self.CurrentVote.No = no
            self.UpdateUI()

            return true
        }, errorHandler: { error in
            EVLog("<--- ERROR query User")
        })
    }

    // Send message as 'bot'
    func SendMessage(_ text: String) {
        let message = Message()
        message.FromFirstName = "bot"
        message.FromLastName = ""
        message.setToFields(GLOBAL_GROUP_ID)
        message.GroupChatName = GLOBAL_GROUP_NAME
        message.Text = text
        EVCloudData.publicDB.saveItem(message, completionHandler: { message in
        }, errorHandler: { error in
            Helper.showError("Could not send message!  \(error.localizedDescription)")
        })
    }

    func SendPic(_ imageAsset: String) {
        // Create the message object that represents the asset
        let message = Message()


        message.setFromFields(getMyRecordID())
        message.setToFields(GLOBAL_GROUP_ID) //self.chatWithId)
        message.GroupChatName = "Spotted Group" // groupChatName
        message.Text = "<foto>"
        message.MessageType = MessageTypeEnum.Picture.rawValue
        message.setAssetFields(imageAsset)

        EVCloudData.publicDB.saveItem(message, completionHandler: {record in
            EVLog("saveItem Message: \(record.recordID.recordName)")
            // self.finishSendingMessage()
        }, errorHandler: {error in
            Helper.showError("Could not send picture message!  \(error.localizedDescription)")
            //self.finishSendingMessage()
        })

    }

}
