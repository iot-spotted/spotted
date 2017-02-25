//
//  GameController.swift
//  AppMessage
//
//  Created by Robert Maratos on 2/23/17.
//  Copyright © 2017 mirabeau. All rights reserved.
//

import EVCloudKitDao
import EVReflection
import Async

class GameController {
    var Group_ID: String = "42"
    var LocalGroupState: GroupState? = nil
    var CurrentVote: Vote? = nil
    var ItUserName: String = ""
    
    var parent: MainViewController
    
    init(parentView: MainViewController) {
        parent = parentView
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
                    self.GetItUser()
                }
                return true
        }, insertedHandler: { item in
            EVLog("GroupState inserted")
            self.LocalGroupState = item
        }, updatedHandler: { item, dataIndex in
            EVLog("GroupState updated")
            self.LocalGroupState = item
            self.GetItUser()
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
            EVLog("Vote inserted \(item)")
//            self.parent.StartVote()
            // TODO
        }, updatedHandler: { item, dataIndex in
            EVLog("Vote updated")
        }, deletedHandler: { recordId, dataIndex in
            EVLog("Vote deleted!!! : \(recordId)")
            self.LocalGroupState = nil
        }, dataChangedHandler: {
            EVLog("Vote data changed!")
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
    
    func GetItUser() {
        EVCloudData.publicDB.dao.query(GameUser(), predicate: NSPredicate(format: "User_Id == '\(LocalGroupState!.It_User_ID)'"),
            completionHandler: { results, stats in
            EVLog("query : result count = \(results.count)")
            if (results.count >= 0) {
                self.ItUserName = results[0].UserFirstName + " " + results[0].UserLastName
                print("It_User=\(self.ItUserName)")
                self.parent.cameraViewController?.updateLabel(label: self.ItUserName)
            }
            return true
        }, errorHandler: { error in
            EVLog("<--- ERROR query User")
        })
    }
    

    func ChangeItUser() {
        EVCloudData.publicDB.dao.query(GameUser(), predicate: NSPredicate(format: "User_Id != '\(LocalGroupState!.It_User_ID)'"),
           completionHandler: { user_results, stats in
            EVLog("query : result count = \(user_results.count)")
            if (user_results.count >= 0) {
                self.LocalGroupState?.It_User_ID = user_results[0].User_Id
                EVCloudData.publicDB.saveItem(self.LocalGroupState!, completionHandler: {record in
                    let createdId = record.recordID.recordName;
                    EVLog("saveItem : \(createdId)");
                    self.GetItUser()
                }, errorHandler: {error in
                    EVLog("<--- ERROR saveItem");
                })
            }
            return true
        }, errorHandler: { error in
            EVLog("<--- ERROR query Message")
        })
    }
    
    func StartVote(Sender_User_ID: String, Asset_ID: String) {
        print("starting vote")
        let vote = Vote()
        vote.Group_ID = Group_ID
        vote.It_User_ID = LocalGroupState!.It_User_ID
        vote.Sender_User_ID = Sender_User_ID
        vote.Asset_ID = Asset_ID
        SaveVote(vote)
    }
    
    func VoteYes(vote: Vote) -> Bool {
        print("voting yes")
        vote.Yes += 1
        var done = false
        if vote.Yes == 2 {
            vote.Status = VoteStatusEnum.Pass.rawValue
            done = true
        }
        SaveVote(vote)
        return done
    }
    
    func VoteNo(vote: Vote) -> Bool  {
        print("voting no")
        vote.No += 1
        var done = false
        if vote.No == 2 {
            vote.Status = VoteStatusEnum.Fail.rawValue
            done = true
        }
        SaveVote(vote)
        return done
    }
    
    func SaveVote(_ vote: Vote) {
        EVCloudData.publicDB.saveItem(vote, completionHandler: {record in
            let createdId = record.recordID.recordName;
            EVLog("vote saveItem : \(createdId)");
        }, errorHandler: {error in
            EVLog("<--- ERROR saveItem");
        })
    }

}
