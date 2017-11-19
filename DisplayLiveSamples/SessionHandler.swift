//
//  SessionHandler.swift
//  DisplayLiveSamples
//
//  Created by Luis Reisewitz on 15.05.16.
//  Copyright © 2016 ZweiGraf. All rights reserved.
//

import AVFoundation
import FirebaseCore
import FirebaseDatabase

class SessionHandler : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate {
    var session = AVCaptureSession()
    let layer = AVSampleBufferDisplayLayer()
    let sampleQueue = DispatchQueue(label: "com.zweigraf.DisplayLiveSamples.sampleQueue", attributes: [])
    let faceQueue = DispatchQueue(label: "com.zweigraf.DisplayLiveSamples.faceQueue", attributes: [])
    let wrapper = DlibWrapper()
    var pnt1:CLong = 0
    var pnt2:CLong = 0
    var pnt3:CLong = 0
    var pnt4:CLong = 0
    var databaseRef:DatabaseReference!
    var currentMetadata: [AnyObject]
    let deviceId = UIDevice.current.identifierForVendor!.uuidString
    let formatter = DateFormatter()
    let sTimer = Date()
    
    override init() {
        currentMetadata = []
        super.init()
        databaseRef = Database.database().reference()
    }
    
    func openSession() {
        let device = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
            .map { $0 as! AVCaptureDevice }
            .filter { $0.position == .front}
            .first!
        
        let input = try! AVCaptureDeviceInput(device: device)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: sampleQueue)
        
        let metaOutput = AVCaptureMetadataOutput()
        metaOutput.setMetadataObjectsDelegate(self, queue: faceQueue)
    
        session.beginConfiguration()
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        if session.canAddOutput(metaOutput) {
            session.addOutput(metaOutput)
        }
        
        session.commitConfiguration()
        
        let settings: [AnyHashable: Any] = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: Int(kCVPixelFormatType_32BGRA)]
        output.videoSettings = settings
    
        // availableMetadataObjectTypes change when output is added to session.
        // before it is added, availableMetadataObjectTypes is empty
        metaOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
        
        wrapper?.prepare()
        
        session.startRunning()
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        if !currentMetadata.isEmpty {
            let boundsArray = currentMetadata
                .flatMap { $0 as? AVMetadataFaceObject }
                .map { (faceObject) -> NSValue in
                    let convertedObject = captureOutput.transformedMetadataObject(for: faceObject, connection: connection)
                    return NSValue(cgRect: convertedObject!.bounds)
            }
            
            wrapper?.doWork(on: sampleBuffer, inRects: boundsArray,long1: &pnt1,long2: &pnt2,long3: &pnt3,long4: &pnt4)
        }
        //print("上x" + String(pnt1) + "上y" + String(pnt2) + "下x" + String(pnt3) + "下y" + String(pnt4))
        print("上：" + String(pnt2))
        print("下：" + String(pnt4))
        print("あき具合：" + String(pnt4 - pnt2))
        moveFace()
        layer.enqueue(sampleBuffer)
    }
    
    func moveFace(){
        let date = Date()
        if sTimer.timeIntervalSinceNow < -1  {
            let dateStr = formatter.string(from: date)
            //let heightPer = (self.view.bounds.height/image.size.height)
            formatter.dateFormat = "MM-dd-HH-mm-ss"
            let moveFace:[String:Any] = ["time":dateStr,"origin_x": pnt2,"origin_y": pnt4];
            databaseRef.childByAutoId().child(deviceId).setValue(moveFace)
            
        }
        sTimer = Date()
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        //print("DidDropSampleBuffer")
        
    }
    
    // MARK: AVCaptureMetadataOutputObjectsDelegate
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        currentMetadata = metadataObjects as [AnyObject]
    }
}
