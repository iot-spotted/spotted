//
//  PhotoViewController.swift
//  SimpleCamera
//
//  Created by Simon Ng on 16/10/2016.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit
import EVCloudKitDao
import Foundation
import CloudKit
import JSQMessagesViewController
import UzysAssetsPickerController
import SwiftLocation
import VIPhotoView
import MapKit
import UIImage_Resize
import Async
import EVCloudKitDao
import EVReflection



class PhotoViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    
    var image:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = image
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Action methods
    
    @IBAction func saver(sender: UIButton) {

        if #available(iOS 10.3, *) {
            UIApplication.shared.setAlternateIconName("Test1", completionHandler: nil)
        } else {
            // Fallback on earlier versions
        }

        }
    
    @IBAction func save(sender: UIButton) {
        guard let imageToSave = image else {
            return
        }
        
        //UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
        
        
        let docDirPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] as NSString
        let filePath =  docDirPath.appendingPathComponent("Image_1.png")
        print(filePath)
        if let myData = UIImagePNGRepresentation(imageToSave) {
            try? myData.write(to: URL(fileURLWithPath: filePath), options: [.atomic])
        }
        
        // Create an asset object for the attached image
        let assetC = Asset()
        assetC.File = CKAsset(fileURL: URL(fileURLWithPath: filePath))
        assetC.FileName = "Image_1.png"
        assetC.FileType = "png"
        
        // Save the asset
        EVCloudData.publicDB.saveItem(assetC, completionHandler: {record in
            EVLog("saveItem Asset: \(record.recordID.recordName)")
            
            // rename the image to recordId for a quick cache reference
            let filemanager = FileManager.default
            let fromFilePath =  docDirPath.appendingPathComponent(record.FileName)
            let toPath = docDirPath.appendingPathComponent(record.recordID.recordName + ".png")
            do {
                try filemanager.moveItem(atPath: fromFilePath, toPath: toPath)
            } catch {}
            
            // Create the message object that represents the asset
            let message = Message()
            
            if #available(iOS 10.0, *) {
                message.setFromFields((EVCloudData.publicDB.dao.activeUser as? CKUserIdentity)?.userRecordID?.recordName ?? "")
            } else {
                message.setFromFields((EVCloudData.publicDB.dao.activeUser as? CKDiscoveredUserInfo)?.userRecordID?.recordName ?? "")
            }
            
            message.setToFields("42") //self.chatWithId)
            message.GroupChatName = "Spotted Group" // groupChatName
            message.Text = "<foto>"
            message.MessageType = MessageTypeEnum.Picture.rawValue
            message.setAssetFields(record.recordID.recordName)
            
            EVCloudData.publicDB.saveItem(message, completionHandler: {record in
                EVLog("saveItem Message: \(record.recordID.recordName)")
               // self.finishSendingMessage()
            }, errorHandler: {error in
                Helper.showError("Could not send picture message!  \(error.localizedDescription)")
                //self.finishSendingMessage()
            })
            
        }, errorHandler: {error in
            Helper.showError("Could not send picture!  \(error.localizedDescription)")
            //self.finishSendingMessage()
        })

        
        
        
        
        dismiss(animated: true, completion: nil)
    }
    
    

}
