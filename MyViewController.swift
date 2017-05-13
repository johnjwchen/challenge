//
//  MyViewController.swift
//  codechallenge
//
//  Created by JIAWEI CHEN on 5/13/17.
//  Copyright © 2017 John. All rights reserved.
//

import UIKit
import AVFoundation

class MyViewController: UIViewController {

    var connection: AVCaptureConnection!
    var output: AVCaptureStillImageOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    @IBOutlet var videoPreviewView: UIView!
    @IBOutlet weak var takeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let previewView = self.videoPreviewView, let previewLayer = self.videoPreviewLayer else {
            return
        }
        previewLayer.bounds = previewView.bounds
        previewLayer.position = CGPoint(x: self.videoPreviewView.bounds.midX, y: self.videoPreviewView.bounds.midY)
        
    }
    
   
    @IBAction func takePictures(_ sender: Any) {
        guard let preview = self.videoPreviewView else {
            return
        }
        preview.setNeedsDisplay()
        
        takeButton.setTitle("Taking...", for: .normal)
//        takeButton.isEnabled = false
        
        
        func runCode(in timeInterval:TimeInterval, _ code:@escaping ()->(Void))
        {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + timeInterval,
                execute: code)
        }
        
        var runCount = 0
        // store 10 images as base64 string in the array
        var imageDataArray = [NSData]()
        
        let closure = { () -> (Void) in
            runCount += 1
            
            // take the picture
            self.takePhoto { (image, error) in
                guard let image = image else {
                    return
                }
                DispatchQueue.global(qos: .userInteractive).async {
                    let imageData:NSData = UIImagePNGRepresentation(image)! as NSData
                    
                    // put it in an array
                    imageDataArray.append(imageData)
                    print(runCount)
                    
                    if runCount > 9 {
                        self.saveImages(imageDataArray)
                    }
                }
            }
            if runCount > 9 {
                self.takeButton.setTitle("Take Pictures", for: .normal)
                //self.takeButton.isEnabled = true
            }
        }
        for i in 1...10 {
            runCode(in: Double(i) * 0.5, closure)
        }
        
    }
    
    // store the images in keychain
    func saveImages(_ imageDataArray: [NSData]) {
        for i in 0..<imageDataArray.count {
            let data = imageDataArray[i]
            
            // TO DO: encrypt the data
            //
            //
            KeychainWrapper.standard.set(data, forKey: String(format: "image-data-", i))
        }
    }
    
    // func
    
    func runCode(in timeInterval:TimeInterval, _ code:@escaping ()->(Void))
    {
        DispatchQueue.main.asyncAfter(
            deadline: .now() + timeInterval,
            execute: code)
    }
    
    
    
    func createCamera() {
        let captureSession = AVCaptureSession()
        
        if captureSession.canSetSessionPreset(AVCaptureSessionPresetHigh) {
            captureSession.sessionPreset = AVCaptureSessionPresetHigh
        } else {
            print("Error: Couldn't set preset = \(AVCaptureSessionPresetHigh)")
            return
        }
        
       
        var inputDevice: AVCaptureDeviceInput!
        do {
            let captureDevice = AVCaptureDevice.defaultDevice(
                withDeviceType: .builtInWideAngleCamera,
                mediaType: AVMediaTypeVideo,
                position: .front)
            inputDevice = try AVCaptureDeviceInput(device: captureDevice)
            
        } catch let error as NSError {

            print(error)
        }
        if captureSession.canAddInput(inputDevice) {
            captureSession.addInput(inputDevice)
        } else {
            print("Error: Couldn't add input device")
            return
        }
        
        let imageOutput = AVCaptureStillImageOutput()
        if captureSession.canAddOutput(imageOutput) {
            captureSession.addOutput(imageOutput)
        } else {
            print("Error: Couldn't add output")
            return
        }
        
        self.output = imageOutput
        
        let connection = imageOutput.connections.first as! AVCaptureConnection
        self.connection = connection
        connection.videoOrientation = AVCaptureVideoOrientation.portrait
        
        captureSession.startRunning()
        
        // This will preview the camera
        let videoLayer = AVCaptureVideoPreviewLayer(session: captureSession)!
        videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoLayer.contentsScale = UIScreen.main.scale
        
        self.videoPreviewView.layer.addSublayer(videoLayer)
        
        self.videoPreviewLayer = videoLayer
    }
    
    func takePhoto(completion: @escaping (UIImage?, NSError?) -> Void) {
        guard let output = self.output, let connection = self.connection else {
            return
        }
        output.captureStillImageAsynchronously(from: connection) { buffer, error in
            if let error = error {
                completion(nil, error as NSError)
            } else {
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                let image = UIImage(data: imageData!, scale: UIScreen.main.scale)
                completion(image, nil)
                
                
            }
        }
    }
}


