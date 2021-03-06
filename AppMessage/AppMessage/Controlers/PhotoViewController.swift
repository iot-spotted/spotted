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
    Receiver = "Receiver",
    ItUser = "ItUser"
}

class PhotoViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var yesButton: UIButton!
    @IBOutlet var noButton: UIButton!
    
    @IBOutlet var yes: UILabel!
    @IBOutlet var no: UILabel!
    @IBOutlet var heading: UILabel!
    @IBOutlet var backgroundLabel: UILabel!
    
    var image:UIImage!
    var mode:Mode!
    var itValue:String!
    var viewLoadDone = false
    
    var gameController: GameController!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        view.bringSubview(toFront: heading)
        cancelButton.isHidden = true
        backgroundLabel.alpha = 0.0
        if mode == Mode.Sender {
            yes.text = ""
            no.text = ""
            self.gameController.photoViewController = self
            heading.text = ""
        } else if mode == Mode.ItUser {
            heading.text = "\(gameController.CurrentVote.Sender_Name) Spotted You!"
            backgroundLabel.alpha = 1.0
            yesButton.isHidden = true
            noButton.isHidden = true
            yes.text = "Yes: 0"
            no.text = "No: 0"
            no.center = CGPoint(x:CGFloat(Float(self.view.frame.width)/4.0), y:noButton.frame.midY)
            yes.center = CGPoint(x:CGFloat(Float(self.view.frame.width)*3.0/4.0), y:yesButton.frame.midY)
        } else {
            yes.isHidden = true
            no.isHidden = true
            yesButton.setTitle("Confirm", for: UIControlState.normal)
            noButton.setTitle("Deny", for: UIControlState.normal)
            heading.text = ""
        }
        imageView.image = image
        viewLoadDone = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


    
    func UpdateUI(_ vote: Vote) {
        if (!viewLoadDone) {
            print("view load not done! :O")
            return
        }
        print("UpdateUI vote.Status=" + vote.Status)
        if vote.Status != VoteStatusEnum.InProgress.rawValue  {
            dismiss(animated: true, completion: nil)
        }
        print("calling updateui")
        yes.text = "Yes: " + String(vote.Yes)
        no.text = "No: " + String(vote.No)
    }
    
    // MARK: - Action methods
    
    @IBAction func saver(sender: UIButton) {

        if #available(iOS 10.3, *) {
            //UIApplication.shared.setAlternateIconName("Test1", completionHandler: nil)
        } else {
            // Fallback on earlier versions
        }

        }
    
    @IBAction func save(sender: UIButton) {
        
        if mode == Mode.Sender{
            backgroundLabel.alpha = 1.0
            heading.text = "Sending..."
            yesButton.isHidden = true
            noButton.isHidden = true
            cancelButton.isHidden = false
            guard let imageToSave = image else {
                return
            }
            
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
                
                
                
                let recordIdMe = getMyRecordID()
                
               

                let name = getMyName()
                
                self.gameController.StartVote(Sender_User_ID: recordIdMe, Sender_Name: name, Asset_ID: record.recordID.recordName)
                
                self.backgroundLabel.alpha = 1.0
                self.heading.text = "Voting in Progress"
                self.yes.text = "0"
                self.no.text = "0"
                
            
                
            }, errorHandler: {error in
                Helper.showError("Could not send picture!  \(error.localizedDescription)")
                //self.finishSendingMessage()
            })
            
            // dismiss(animated: true, completion: nil)
        }
        else {
            gameController.VoteYes()
            dismiss(animated: true, completion: nil)
        }
    
    }
    
    @IBAction func no(sender: UIButton) {
        
        if mode == Mode.Receiver{
            gameController.VoteNo()
            dismiss(animated: true, completion: nil)
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(sender: UIButton) {
        gameController.CancelVote()
        dismiss(animated: true, completion: nil)
    }
    
    

}
