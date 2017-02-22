//
//  SimpleCameraController.swift
//  SimpleCamera
//
//  Created by Simon Ng on 16/10/2016.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit
import AVFoundation

class HomeViewController: UIViewController {
    
    @IBOutlet var cameraButton:UIButton!
    @IBOutlet var chatButton:UIButton!
    
    let captureSession = AVCaptureSession()
    
    var backFacingCamera: AVCaptureDevice?
    var frontFacingCamera: AVCaptureDevice?
    var currentDevice: AVCaptureDevice?
    
    var stillImageOutput: AVCaptureStillImageOutput?
    var stillImage: UIImage?
    
    var cameraPreviewLayer:AVCaptureVideoPreviewLayer?
    var toggleCameraGestureRecognizer = UISwipeGestureRecognizer()
    
    var zoomInGestureRecognizer = UISwipeGestureRecognizer()
    var zoomOutGestureRecognizer = UISwipeGestureRecognizer()
    
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
            view.bringSubview(toFront: chatButton)
            captureSession.startRunning()
        } catch {
            print(error)
        }
        
        
        // Toggle Camera recognizer
        toggleCameraGestureRecognizer.direction = .up
        toggleCameraGestureRecognizer.addTarget(self, action: #selector(toggleCamera))
        view.addGestureRecognizer(toggleCameraGestureRecognizer)
        
        // Zoom In recognizer
        zoomInGestureRecognizer.direction = .right
        zoomInGestureRecognizer.addTarget(self, action: #selector(zoomIn))
        view.addGestureRecognizer(zoomInGestureRecognizer)
        
        // Zoom Out recognizer
        zoomOutGestureRecognizer.direction = .left
        zoomOutGestureRecognizer.addTarget(self, action: #selector(zoomOut))
        view.addGestureRecognizer(zoomOutGestureRecognizer)
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
        stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (imageDataSampleBuffer, error) -> Void in
            
            if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer) {
                self.stillImage = UIImage(data: imageData)
                self.performSegue(withIdentifier: "showPhoto", sender: self)
            }
        })
    }
    
    @IBAction func goToChat(sender: UIButton) {
        NotificationCenter.default.post(name: Notification.Name(rawValue:"loadChat"), object: nil)
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
    
    func zoomIn() {
        if let zoomFactor = currentDevice?.videoZoomFactor {
            if zoomFactor < 5.0 {
                let newZoomFactor = min(zoomFactor + 1.0, 5.0)
                do {
                    try currentDevice?.lockForConfiguration()
                    currentDevice?.ramp(toVideoZoomFactor: newZoomFactor, withRate: 1.0)
                    currentDevice?.unlockForConfiguration()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func zoomOut() {
        if let zoomFactor = currentDevice?.videoZoomFactor {
            if zoomFactor > 1.0 {
                let newZoomFactor = max(zoomFactor - 1.0, 1.0)
                do {
                    try currentDevice?.lockForConfiguration()
                    currentDevice?.ramp(toVideoZoomFactor: newZoomFactor, withRate: 1.0)
                    currentDevice?.unlockForConfiguration()
                } catch {
                    print(error)
                }
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
