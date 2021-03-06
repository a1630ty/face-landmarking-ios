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
    var mouseUp:CLong = 0
    var mouseDown:CLong = 0
    var rEyeUp:CLong = 0
    var rEyeDown:CLong = 0
    var faceCenterUpx:CLong = 0
    var faceCenterDownx:CLong = 0
    var faceCenterUpy:CLong = 0
    var faceCenterDowny:CLong = 0
    var databaseRef:DatabaseReference!
    var currentMetadata: [AnyObject]
    let deviceId = UIDevice.current.identifierForVendor!.uuidString
    let formatter = DateFormatter()
    var sTimer = Date()
    var mCount:Int = 0
    
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
            //Thread.sleep(forTimeInterval: 2)
            wrapper?.doWork(on: sampleBuffer, inRects: boundsArray,slong1: &mouseUp,slong2: &mouseDown,slong3: &rEyeUp,slong4: &rEyeDown,slong5: &faceCenterUpx,slong6: &faceCenterUpy,slong7: &faceCenterDownx,slong8: &faceCenterDowny)
        }
        //print("上x" + String(pnt1) + "上y" + String(pnt2) + "下x" + String(pnt3) + "下y" + String(pnt4))
        //print("上：" + String(mouseUp))
        //print("下：" + String(mouseDown))
        if faceCenterDowny > 0 {
            let heightPer = (bsHeight/CGFloat(faceCenterDowny - faceCenterUpy))
            //print("heightPer：" + String(CLong(heightPer)))
//            print("口あき具合：" + String(CLong(CGFloat(mouseDown) * heightPer - CGFloat(mouseUp) * heightPer)))
//            print("目あき具合：" + String(CLong(CGFloat(rEyeUp) * heightPer - CGFloat(rEyeDown) * heightPer)))
//            print("倍率：" + String(faceCenterDowny - faceCenterUpy))
//            print("傾き：" + String(CLong(CGFloat(faceCenterUpx - faceCenterDownx) * heightPer)))
            let date = Date()
            if NSDate().timeIntervalSince(sTimer) > 1  {
                let dateStr = formatter.string(from: date)
                //let heightPer = (self.view.bounds.height/image.size.height)
                formatter.dateFormat = "MM-dd-HH-mm-ss"
                let moveFace:[String:Any] = ["time":dateStr,"mouse": CLong(CGFloat(mouseDown) * heightPer - CGFloat(mouseUp) * heightPer),"eye": CLong(CGFloat(rEyeUp) * heightPer - CGFloat(rEyeDown) * heightPer),"line": CLong(CGFloat(faceCenterUpx - faceCenterDownx) * heightPer)];
                databaseRef.childByAutoId().child(deviceId).setValue(moveFace)
                sTimer = Date()
                if CLong(CGFloat(mouseDown) * heightPer - CGFloat(mouseUp) * heightPer) > 200 {
                    mCount = mCount + 1
                    print(String(mCount))
                } else if mCount > 0 {
                    mCount = mCount - 1
                }
                if mCount > 2 {
                    let akubi:[String:Any] = ["time":dateStr,"あくび":1]
                    databaseRef.childByAutoId().child(deviceId).setValue(akubi)
                    mCount = 0
                    
                }
                
            }
        }

        layer.enqueue(sampleBuffer)
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        //print("DidDropSampleBuffer")
        
    }
    
    // MARK: AVCaptureMetadataOutputObjectsDelegate
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        currentMetadata = metadataObjects as [AnyObject]
    }
}
