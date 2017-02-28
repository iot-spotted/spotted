//
//  Game.swift
//  AppMessage
//
//  Created by Robert Maratos on 2/22/17.
//  Copyright © 2017 mirabeau. All rights reserved.
//

//
//  Message.swift
//
//  Created by Edwin Vermeer on 01-07-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//
// SwiftLint ignore variable_name

import CloudKit
import EVReflection

enum VoteStatusEnum: String {
    case InProgress = "I",
    Pass = "P",
    Fail = "F"
}

class GameUser: CKDataObject {
    var User_ID: String = ""
    var Name: String = ""
    var Score: Int = 0
}

class GroupState: CKDataObject {
    var Group_ID: String = ""
    var It_User_ID: String = ""
    var It_User_Name: String = ""
}

class Vote: CKDataObject {
    var Group_ID: String = ""
    var It_User_ID: String = ""
    var It_User_Name: String = ""
    var Sender_User_ID: String = ""
    var Sender_Name: String = ""
    var Asset_ID: String = ""
    var Status: String = VoteStatusEnum.InProgress.rawValue
    var Yes: Int = 0
    var No: Int = 0
}

//class Vote: CKDataObject {
//    var Vote_ID: String = ""
//    var Yes: Bool = false
//}
