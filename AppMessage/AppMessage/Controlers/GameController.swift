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
    var GroupID: String = "42"
    var LocalGroupState: GroupState? = nil
    var ItUserName: String = ""
    
    init(updateLabelHandler:@escaping ((_ label: String) -> Void)) {
        initializeCommunication(updateLabelHandler: updateLabelHandler)
    }
    
    func initializeCommunication(_ retryCount: Double = 1, updateLabelHandler:@escaping ((_ label: String) -> Void)) {
        // GroupState Connection
        EVCloudData.publicDB.connect(GroupState(), predicate: NSPredicate(format: "Group_ID == '\(GroupID)'"), filterId: "Group_ID_\(GroupID)",
            completionHandler: { results, status in
                EVLog("GroupState results = \(results.count)")
                if results.count > 0 {
                    self.LocalGroupState = results[0]
                    print("Got LocalGroupState for \(self.LocalGroupState!.Group_ID)")
                    self.GetItUser(updateLabelHandler)
                }
                return true
        }, insertedHandler: { item in
            EVLog("GroupState inserted \(item)")
            self.LocalGroupState = item
        }, updatedHandler: { item, dataIndex in
            EVLog("GroupState updated \(item)")
            self.LocalGroupState = item
            self.GetItUser(updateLabelHandler)
        }, deletedHandler: { recordId, dataIndex in
            EVLog("GroupState deleted!!! : \(recordId)")
            self.LocalGroupState = nil
        }, dataChangedHandler: {
            EVLog("GroupState data changed!")
        }, errorHandler: { error in
            switch EVCloudKitDao.handleCloudKitErrorAs(error, retryAttempt: retryCount) {
            case .retry(let timeToWait):
                Async.background(after: timeToWait) {
                    self.initializeCommunication(retryCount + 1, updateLabelHandler:updateLabelHandler)
                }
            case .fail:
                Helper.showError("Could not load groupdata: \(error.localizedDescription)")
            default: // For here there is no need to handle the .Success, and .RecoverableError
                break
            }
        });
    }
    
    func GetItUser(_ updateLabelHandler:@escaping ((_ label: String) -> Void)) {
        EVCloudData.publicDB.dao.query(GameUser(), predicate: NSPredicate(format: "User_Id == '\(LocalGroupState!.It_User_ID)'"),
            completionHandler: { results, stats in
            EVLog("query : result count = \(results.count)")
            if (results.count >= 0) {
                self.ItUserName = results[0].UserFirstName + " " + results[0].UserLastName
                print("It_User=\(self.ItUserName)")
                updateLabelHandler(self.ItUserName)
            }
            return true
        }, errorHandler: { error in
            EVLog("<--- ERROR query User")
        })
    }
    

    func ChangeItUser(_ updateLabelHandler:@escaping ((_ label: String) -> Void)) {
        EVCloudData.publicDB.dao.query(GameUser(), predicate: NSPredicate(format: "User_Id != '\(LocalGroupState!.It_User_ID)'"),
           completionHandler: { user_results, stats in
            EVLog("query : result count = \(user_results.count)")
            if (user_results.count >= 0) {
                self.LocalGroupState?.It_User_ID = user_results[0].User_Id
                EVCloudData.publicDB.saveItem(self.LocalGroupState!, completionHandler: {record in
                    let createdId = record.recordID.recordName;
                    EVLog("saveItem : \(createdId)");
                    self.GetItUser(updateLabelHandler)
                }, errorHandler: {error in
                    EVLog("<--- ERROR saveItem");
                })
            }
            return true
        }, errorHandler: { error in
            EVLog("<--- ERROR query Message")
        })
    }
}
