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
    @IBOutlet var titleLabel:UILabel!
    
    let captureSession = AVCaptureSession()
    
    var backFacingCamera: AVCaptureDevice?
    var frontFacingCamera: AVCaptureDevice?
    var currentDevice: AVCaptureDevice?
    
    var stillImageOutput: AVCaptureStillImageOutput?
    var stillImage: UIImage?
    var navTitle: UINavigationItem?
    
    var cameraPreviewLayer:AVCaptureVideoPreviewLayer?
    //var toggleCameraGestureRecognizer = UISwipeGestureRecognizer()
    
    var zoomGestureRecognizer = UIPinchGestureRecognizer()
    var initialVideoZoomFactor: CGFloat = 0.0

    var gameController: GameController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowRadius = 50
        titleLabel.layer.shadowOpacity = 50
        
        // Preset the session for taking photo in full resolution
        captureSession.sessionPreset = AVCaptureSessionPresetiFrame960x540
        
        
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
            view.bringSubview(toFront: titleLabel)
            
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
    }
    
    override func viewDidLayoutSubviews() {
        let topBar: UINavigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 60))
        topBar.barStyle = UIBarStyle.blackOpaque
        topBar.isTranslucent = true
        topBar.setBackgroundImage(UIImage(), for: .default)
        topBar.shadowImage = UIImage()
        topBar.tintColor = UIColor.white
        topBar.layer.shadowColor = UIColor.black.cgColor
        topBar.layer.shadowRadius = 50
        topBar.layer.shadowOpacity = 50
        //topBar.layer.shadowOffset = CGSize(width:100, height:100)
        self.view.addSubview(topBar)
//        self.navTitle = UINavigationItem(title: ("Find " + (self.gameController?.LocalGroupState.It_User_Name)!) + "!")
        self.navTitle = UINavigationItem(title: (""))
        let chat = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.compose, target: nil, action: #selector(loadChat))
        let profile = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.organize, target: nil, action: #selector(loadProfile))
        self.navTitle?.rightBarButtonItem = chat
        self.navTitle?.leftBarButtonItem = profile
        topBar.setItems([self.navTitle!], animated: false)
//        if ((self.gameController?.LocalGroupState.It_User_Name) == getMyName()){
//            self.titleLabel.text = "You're it!"
//            self.disableCamera()
//        }
//        else{
//            self.titleLabel.text = "Find " + (self.gameController?.LocalGroupState.It_User_Name)! + "!"
//            self.enableCamera()
//        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addText(inImage image: UIImage) -> UIImage {
        
        let textColor = UIColor.white
        let textFont = UIFont(name: "Helvetica Bold", size: 100)!
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment.center
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)
        
        var textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor, NSParagraphStyleAttributeName:
            style] as [String : Any]
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        
        var rect = CGRect(origin: CGPoint(x:0, y:150), size: image.size)
        var text = self.gameController?.LocalGroupState.It_User_Name.components(separatedBy: " ").first?.uppercased()
        text?.draw(in: rect, withAttributes: textFontAttributes)
        
        rect = CGRect(origin: CGPoint(x:0, y:image.size.height-250), size: image.size)
        text = "SPOTTED"
        textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor, NSParagraphStyleAttributeName:
            style] as [String : Any]
        text?.draw(in: rect, withAttributes: textFontAttributes)

        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    // MARK: - Action methods

    @IBAction func capture(sender: UIButton) {
        let videoConnection = stillImageOutput?.connection(withMediaType: AVMediaTypeVideo)
        videoConnection?.videoScaleAndCropFactor = (currentDevice?.videoZoomFactor)!
        stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (imageDataSampleBuffer, error) -> Void in
            
            if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer) {
                let image = UIImage(data: imageData)
                self.stillImage = self.addText(inImage: image!)
                self.performSegue(withIdentifier: "showPhoto", sender: self)
            }
        })
    }
    
    func updateLabel(label: String) {
        DispatchQueue.main.async {
//            self.navTitle?.title = "Find " + label + "!"
            if ((self.gameController?.LocalGroupState.It_User_Name) == getMyName()){
                self.titleLabel.text = "You're it!"
                self.disableCamera()
            }
            else{
                self.titleLabel.text = "Find " + (self.gameController?.LocalGroupState.It_User_Name)! + "!"
                self.enableCamera()
            }
            print("Set It User Label=\(label)")
        }
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
            photoViewController.itValue = self.gameController?.LocalGroupState.It_User_Name
            photoViewController.mode = Mode.Sender
            photoViewController.gameController = gameController
        }
    }
    
    
    func StartVote() {
        print("camera ui start vote")
    }
    
    func disableCamera(){
        cameraButton.isEnabled = false
    }
    
    func enableCamera(){
        cameraButton.isEnabled = true
    }
}
