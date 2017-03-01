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
    @IBOutlet var scoreLabel: UILabel?
        
    override func viewDidLoad() {
        let topBar: UINavigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 60))
        topBar.barStyle = UIBarStyle.blackOpaque
        self.view.addSubview(topBar)
        let barItem = UINavigationItem(title: "Profile")
        let back = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.camera, target: nil, action: #selector(loadCamera))
        barItem.rightBarButtonItem = back
        topBar.setItems([barItem], animated: false)
        
        label?.text = getMyName()
    
        EVCloudData.publicDB.dao.query(GameUser(), predicate: NSPredicate(format: "User_ID == '\(getMyRecordID())'"),
           completionHandler: { results, stats in
            EVLog("query : result count = \(results.count)")
            if (results.count == 1) {
                print("setting user...")
                let user = results[0]
                self.scoreLabel?.text = String(user.Score)
            }
            return true
        }, errorHandler: { error in
            EVLog("<--- ERROR query User")
        })
    }
    
    func loadCamera() {
        NotificationCenter.default.post(name: Notification.Name(rawValue:"loadCamera"), object: nil)
    }
}

