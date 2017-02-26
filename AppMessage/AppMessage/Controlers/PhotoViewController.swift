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

enum Mode: String {
    case Sender = "Sender",
    Receiver = "Receiver"
}

class PhotoViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var yes: UILabel!
    @IBOutlet var no: UILabel!
    @IBOutlet var heading: UILabel!
    
    var image:UIImage?
    var mode:Mode?
    var itValue:String?
    var viewLoadDone = false
    
    var gameController: GameController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if mode == Mode.Sender {
            yes.text = ""
            no.text = ""
        }
        else {
            yes.text = "0"
            no.text = "0"
        }
        imageView.image = image
        heading.text = "Is this " + itValue! + "?"
        viewLoadDone = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func textToImage(drawText text: NSString, inImage image: UIImage, atPoint point: CGPoint) -> UIImage {
        
        let imageView = UIImageView(image: image)
        imageView.backgroundColor = UIColor.clear
        imageView.frame = CGRect(x:0, y:0, width:image.size.width, height:image.size.height)
        
        let label = UILabel(frame: CGRect(x:0, y:0, width:image.size.width, height:image.size.height))
        label.backgroundColor = UIColor.clear
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.text = text as String
        label.adjustsFontSizeToFitWidth = true
        
        UIGraphicsBeginImageContext(label.bounds.size);
        imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        label.layer.render(in: UIGraphicsGetCurrentContext()!)
        let imageWithText = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        
        return imageWithText!
    }
    
    func UpdateUI(_ vote: Vote) {
        if (!viewLoadDone) {
            print("view load not done! :O")
            return
        }
        if vote.Status != VoteStatusEnum.InProgress.rawValue  {
            dismiss(animated: true, completion: nil)
        }
        print("calling updateui")
        yes.text = String(vote.Yes)
        no.text = String(vote.No)
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
        
        if mode == Mode.Sender{
            guard let imageToSave = image else {
                return
            }
            //UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
            
            //let newImage = textToImage(drawText:"CHILL", inImage: imageToSave, atPoint: CGPoint(x:20, y:20))
            let newImage = imageToSave
            
            let docDirPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] as NSString
            let filePath =  docDirPath.appendingPathComponent("Image_1.png")
            print(filePath)
            if let myData = UIImagePNGRepresentation(newImage) {
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
                
                var recordIdMe: String?
                
                if #available(iOS 10.0, *) {
                    recordIdMe = (EVCloudData.publicDB.dao.activeUser as? CKUserIdentity)?.userRecordID?.recordName
                } else {
                    recordIdMe = (EVCloudData.publicDB.dao.activeUser as? CKDiscoveredUserInfo)?.userRecordID?.recordName
                }
                self.gameController?.StartVote(Sender_User_ID: recordIdMe!, Asset_ID: record.recordID.recordName)
                
                
                
                message.setToFields(GLOBAL_GROUP_ID) //self.chatWithId)
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
        else {
            gameController?.VoteYes()
            dismiss(animated: true, completion: nil)
        }
    
    }
    
    @IBAction func no(sender: UIButton) {
        
        if mode == Mode.Sender{
            dismiss(animated: true, completion: nil)
        }
        else {
            gameController?.VoteNo()
            dismiss(animated: true, completion: nil)
        }
    }
    
    

}
