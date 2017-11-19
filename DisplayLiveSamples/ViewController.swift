//
//  ViewController.swift
//  DisplayLiveSamples
//
//  Created by Luis Reisewitz on 15.05.16.
//  Copyright © 2016 ZweiGraf. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox
import FirebaseCore
import FirebaseDatabase

class ViewController: UIViewController {
    let sessionHandler = SessionHandler()
    @IBOutlet weak var preview: UIView!
    @IBOutlet weak var buttonFatigue: UIButton!
    var databaseRf:DatabaseReference!
    let dId = UIDevice.current.identifierForVendor!.uuidString
    let formatter = DateFormatter()
    override func viewDidLoad() {
        super.viewDidLoad()
        databaseRf = Database.database().reference()
        // Do any additional setup after loading the view, typically from a nib.
//        buttonFatigue.addTarget(self, action: Selector("onClickMyButton"), for: .touchUpInside)
        bsHeight = self.view.bounds.height
    }

    @IBAction func tcButton(_ sender: Any) {
        print("onClickMyButton:")
        let date = Date()
        let dateStr = formatter.string(from: date)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        formatter.dateFormat = "MM-dd-HH-mm-ss"
        let fatigue:[String:Any] = ["time":dateStr,"fatigue":"Im tired"];
        
        databaseRf.childByAutoId().child(dId).setValue(fatigue)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        sessionHandler.openSession()

        let layer = sessionHandler.layer
        layer.frame = preview.bounds
        preview.layer.addSublayer(layer)
        
        view.layoutIfNeeded()

    }

}

