//
//  ProfileViewController.swift
//  
//
//  Created by Jake Weiss on 2/22/17.
//
//

import UIKit
import CloudKit
import EVCloudKitDao

class ProfileViewController: UIViewController {
    
    @IBOutlet var label: UILabel?
    
    override func viewDidLayoutSubviews() {
        let topBar: UINavigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 60))
        topBar.barStyle = UIBarStyle.blackOpaque
        self.view.addSubview(topBar)
        let barItem = UINavigationItem(title: "Profile")
        let back = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.camera, target: nil, action: #selector(loadCamera))
        barItem.rightBarButtonItem = back
        topBar.setItems([barItem], animated: false)
        
        var senderFirstName = ""
        var senderLastName = ""
        
        if #available(iOS 10.0, *) {
            senderFirstName = (EVCloudData.publicDB.dao.activeUser as? CKUserIdentity)?.nameComponents?.givenName ?? ""
            senderLastName = (EVCloudData.publicDB.dao.activeUser as? CKUserIdentity)?.nameComponents?.familyName ?? ""
        } else {
            senderFirstName = (EVCloudData.publicDB.dao.activeUser as? CKDiscoveredUserInfo)?.firstName ?? ""
            senderLastName    = (EVCloudData.publicDB.dao.activeUser as? CKDiscoveredUserInfo)?.lastName ?? ""
        }
        
       label?.text = "\(senderFirstName) \(senderLastName)"
        
    }
    
    func loadCamera() {
        NotificationCenter.default.post(name: Notification.Name(rawValue:"loadCamera"), object: nil)
    }
}

