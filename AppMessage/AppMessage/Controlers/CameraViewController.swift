//
//  SimpleCameraController.swift
//  SimpleCamera
//
//  Created by Simon Ng on 16/10/2016.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit
import AVFoundation
import CloudKit
import EVCloudKitDao
import EVReflection
import Async

class CameraViewController: UIViewController {
    
    @IBOutlet var cameraButton:UIButton!
    @IBOutlet var itUserLabel:UILabel!
    
    let captureSession = AVCaptureSession()
    
    var backFacingCamera: AVCaptureDevice?
    var frontFacingCamera: AVCaptureDevice?
    var currentDevice: AVCaptureDevice?
    
    var stillImageOutput: AVCaptureStillImageOutput?
    var stillImage: UIImage?
    
    var cameraPreviewLayer:AVCaptureVideoPreviewLayer?
    //var toggleCameraGestureRecognizer = UISwipeGestureRecognizer()
    
    var zoomGestureRecognizer = UIPinchGestureRecognizer()
    var initialVideoZoomFactor: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Preset the session for taking photo in full resolution
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice]
        
        // Get the front and back-facing camera for taking photos
        for device in devices {
            if device.position == AVCaptureDevicePosition.back {
                backFacingCamera = device
            } else if device.position == AVCaptureDevicePosition.front {
                frontFacingCamera = device
            }
        }
        currentDevice = backFacingCamera
        
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice)
            
            // Configure the session with the output for capturing still images
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            // Configure the session with the input and the output devices
            captureSession.addInput(captureDeviceInput)
            captureSession.addOutput(stillImageOutput)
            
            // Provide a camera preview
            cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            view.layer.addSublayer(cameraPreviewLayer!)
            cameraPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            cameraPreviewLayer?.frame = view.layer.frame
            
            // Bring the camera button to front
            view.bringSubview(toFront: cameraButton)
            
            view.bringSubview(toFront: itUserLabel)

            captureSession.startRunning()
        } catch {
            print(error)
        }
        
        
        // Toggle Camera recognizer
        //toggleCameraGestureRecognizer.direction = .up
        //toggleCameraGestureRecognizer.addTarget(self, action: #selector(toggleCamera))
        //view.addGestureRecognizer(toggleCameraGestureRecognizer)
        
        // Zoom In recognizer
        zoomGestureRecognizer.addTarget(self, action: #selector(zoom))
        view.addGestureRecognizer(zoomGestureRecognizer)
        
        var It_User_ID = ""
        EVCloudData.publicDB.dao.query(GroupState(), predicate: NSPredicate(format: "Group_ID == '42'"),
            completionHandler: { results, stats in
                EVLog("query : result count = \(results.count)")
                if (results.count >= 0) {
                    print(results[0].Group_ID)
                    print(results[0].It_User_ID)
                    It_User_ID = results[0].It_User_ID
                    print("It_User_ID1=\(It_User_ID)")
                }
                /// QUERY USER
                print("It_User_ID2=\(It_User_ID)")
                
                EVCloudData.publicDB.dao.query(GameUser(), predicate: NSPredicate(format: "User_Id == '\(It_User_ID)'"),
                                               completionHandler: { results, stats in
                                                EVLog("query : result count = \(results.count)")
                                                if (results.count >= 0) {
                                                    print(results[0].UserFirstName)
                                                    print(results[0].UserLastName)
                                                    DispatchQueue.main.async {
                                                        self.itUserLabel.text = results[0].UserFirstName + " " + results[0].UserLastName
                                                        print("It_User1=\(results[0].UserFirstName + " " + results[0].UserLastName)")
                                                    }
                                                }
                                                return true
                }, errorHandler: { error in
                    EVLog("<--- ERROR query Message")
                })
                
                /// END QUERY USER
                return true
        }, errorHandler: { error in
            EVLog("<--- ERROR query Message")
        })
        
        print("CHANGING IT USER?")
        EVCloudData.publicDB.dao.query(GroupState(), predicate: NSPredicate(format: "Group_ID == '42'"),
                                       completionHandler: { group_results, stats in
                                        EVLog("query : result count = \(group_results.count)")
                                        if (group_results.count >= 0) {
                                            print(group_results[0].Group_ID)
                                            print(group_results[0].It_User_ID)
                                            It_User_ID = group_results[0].It_User_ID
                                            print("It_User_ID1=\(It_User_ID)")
                                        }
                                        /// QUERY USER
                                        var It_User = ""
                                        
                                        EVCloudData.publicDB.dao.query(GameUser(), predicate: NSPredicate(format: "User_Id != '\(It_User_ID)'"),
                                                                       completionHandler: { user_results, stats in
                                                                        EVLog("query : result count = \(user_results.count)")
                                                                        if (user_results.count >= 0) {
                                                                            print(user_results[0].UserFirstName)
                                                                            print(user_results[0].UserLastName)
                                                                            It_User = user_results[0].UserFirstName + " " + user_results[0].UserLastName
                                                                            print("New_It_User1=\(It_User)")
                                                                            group_results[0].It_User_ID = user_results[0].User_Id
                                                                            EVCloudData.publicDB.dao.saveItem(group_results[0], completionHandler: {record in
                                                                                let createdId = record.recordID.recordName;
                                                                                EVLog("saveItem : \(createdId)");
                                                                            }, errorHandler: {error in
                                                                                EVLog("<--- ERROR saveItem");
                                                                            })
                                                                        }
                                                                        return true
                                        }, errorHandler: { error in
                                            EVLog("<--- ERROR query Message")
                                        })
                                        
                                        /// END QUERY USER
                                        return true
        }, errorHandler: { error in
            EVLog("<--- ERROR query Message")
        })
        
        



    }
    
    override func viewDidLayoutSubviews() {
        let topBar: UINavigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 60))
        topBar.barStyle = UIBarStyle.blackOpaque
        self.view.addSubview(topBar)
        let barItem = UINavigationItem(title: "Spotted")
        let chat = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.compose, target: nil, action: #selector(loadChat))
        let profile = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.organize, target: nil, action: #selector(loadProfile))
        barItem.rightBarButtonItem = chat
        barItem.leftBarButtonItem = profile
        topBar.setItems([barItem], animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Action methods

    @IBAction func capture(sender: UIButton) {
        let videoConnection = stillImageOutput?.connection(withMediaType: AVMediaTypeVideo)
        videoConnection?.videoScaleAndCropFactor = (currentDevice?.videoZoomFactor)!
        stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (imageDataSampleBuffer, error) -> Void in
            
            if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer) {
                self.stillImage = UIImage(data: imageData)
                self.performSegue(withIdentifier: "showPhoto", sender: self)
            }
        })
    }
    
    func loadChat() {
        NotificationCenter.default.post(name: Notification.Name(rawValue:"loadChat"), object: nil)
    }
    func loadProfile() {
        NotificationCenter.default.post(name: Notification.Name(rawValue:"loadProfile"), object: nil)
    }

    
    // MARK: - Camera methods
    
    func toggleCamera() {
        captureSession.beginConfiguration()
        
        // Change the device based on the current camera
        let newDevice = (currentDevice?.position == AVCaptureDevicePosition.back) ? frontFacingCamera : backFacingCamera
        
        // Remove all inputs from the session
        for input in captureSession.inputs {
            captureSession.removeInput(input as! AVCaptureDeviceInput)
        }
        
        // Change to the new input
        let cameraInput:AVCaptureDeviceInput
        do {
            cameraInput = try AVCaptureDeviceInput(device: newDevice)
        } catch {
            print(error)
            return
        }
        
        if captureSession.canAddInput(cameraInput) {
            captureSession.addInput(cameraInput)
        }
        
        currentDevice = newDevice
        captureSession.commitConfiguration()
    }
    
    func zoom(sender: UIPinchGestureRecognizer) {
        
        if (sender.state == UIGestureRecognizerState.began) {
            initialVideoZoomFactor = (currentDevice?.videoZoomFactor)!
        } else {
            let scale: CGFloat = min(max(1, initialVideoZoomFactor * sender.scale), 4)
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.01)
            cameraPreviewLayer?.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))
            CATransaction.commit()
            do {
                try currentDevice?.lockForConfiguration()
                currentDevice?.videoZoomFactor = scale
                currentDevice?.unlockForConfiguration()
            } catch {
                NSLog("error!")
            }
            
        }        
    }
    
    // MARK: - Segues
    
    @IBAction func unwindToCameraView(segue: UIStoryboardSegue) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showPhoto" {
            let photoViewController = segue.destination as! PhotoViewController
            photoViewController.image = stillImage
        }
    }
}
