//
//  Util.swift
//  AppMessage
//
//  Created by Robert Maratos on 2/22/17.
//  Copyright © 2017 mirabeau. All rights reserved.
//

import Foundation
import EVCloudKitDao
import CloudKit

func showNameFor(_ contact: AnyObject) -> String {
    if #available(iOS 10.0, *) {
        return showNameFor10(contact as! CKUserIdentity)
    } else {
        return showNameFor9(contact as! CKDiscoveredUserInfo)
    }
    
}

@available(iOS 10.0, *)
func showNameFor10(_ contact: CKUserIdentity) -> String {
    let nickname = contact.nameComponents?.nickname ?? ""
    let givenName = contact.nameComponents?.givenName ?? ""
    let familyName = contact.nameComponents?.familyName ?? ""
    let nameSuffix = contact.nameComponents?.nameSuffix ?? ""
    let middleName = contact.nameComponents?.middleName ?? ""
    let namePrefix = contact.nameComponents?.namePrefix ?? ""
    let emailAddress = contact.lookupInfo?.emailAddress ?? ""
    let phoneNumber = contact.lookupInfo?.phoneNumber ?? ""
    
    let name = "\(nickname) - \(givenName) \(middleName) \(namePrefix) \(familyName) \(nameSuffix) - \(emailAddress) \(phoneNumber))"  // contact.userRecordID?.recordName
    return name.replacingOccurrences(of: "   ", with: " ").replacingOccurrences(of: "  ", with: " ")
}

func showNameFor9(_ contact: CKDiscoveredUserInfo) -> String {
    var firstName: String = ""
    var lastName: String = ""
    if #available(iOS 9.0, *) {
        firstName = contact.displayContact?.givenName ?? ""
        lastName = contact.displayContact?.familyName ?? ""
    } else {
        firstName = contact.firstName ?? ""
        lastName = contact.lastName ?? ""
    }
    return "\(firstName) \(lastName)"
}
