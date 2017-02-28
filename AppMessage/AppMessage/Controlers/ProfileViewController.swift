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
    
    override func viewDidLoad() {
        let topBar: UINavigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 60))
        topBar.barStyle = UIBarStyle.blackOpaque
        self.view.addSubview(topBar)
        let barItem = UINavigationItem(title: "Profile")
        let back = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.camera, target: nil, action: #selector(loadCamera))
        barItem.rightBarButtonItem = back
        topBar.setItems([barItem], animated: false)
        
       label?.text = getMyName()
        
    }
    
    func loadCamera() {
        NotificationCenter.default.post(name: Notification.Name(rawValue:"loadCamera"), object: nil)
    }
}

