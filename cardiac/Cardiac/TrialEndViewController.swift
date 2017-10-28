//
//  ManualInputDataViewController.swift
//  Cardiac
//
//  Created by Eileen Guo on 4/7/17.
//  Copyright © 2017 Eileen Guo. All rights reserved.
//

import Foundation
import UIKit

class TrialEndViewController: UIViewController, UITextFieldDelegate {
    
    let directoryModel = DirectoryModel.sharedInstance
    let connectivityManager = ConnectivityManager.sharedInstance
    let bioHarness = BioHarness.sharedInstance
    let e4 = E4Controller.sharedInstance

    let SUBMIT_RND = "submitRound"
    let RESET_RND = "resetRound"
    let GO_HOME = "goToHomeScreen"

    @IBOutlet weak var cardioBuddyBPM: UITextField!
    @IBOutlet weak var pulseOxSp02: UITextField!
    @IBOutlet weak var pulseOxBPM: UITextField!
    @IBOutlet weak var iCareBloodViscosity: UITextField!
    @IBOutlet weak var iCarePulseOx: UITextField!
    @IBOutlet weak var iCareBPM: UITextField!
    @IBOutlet weak var iCareBPSystolic: UITextField!
    @IBOutlet weak var iCareBPDiastolic: UITextField!
    @IBOutlet weak var groundTruthBPSystolic: UITextField!
    @IBOutlet weak var groundTruthBPDiastolic: UITextField!
    
    enum TextField: Int {
        case cbBPM, poSp02, poBPM, icBloodViscosity, icPO, icBPM, icBPS, icBPD, gtBPS, gtBPD
    }
    
    @IBAction func screenTapped(_ sender: Any) {
        UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil);
        allFieldsCompleted()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        connectivityManager.delegate = self
        
        if (self.restorationIdentifier == "bodyCamSubmit") {
            cardioBuddyBPM.delegate = self
            pulseOxSp02.delegate = self
            pulseOxBPM.delegate = self
            iCareBloodViscosity.delegate = self
            iCarePulseOx.delegate = self
            iCareBPM.delegate = self
            iCareBPDiastolic.delegate = self
            iCareBPSystolic.delegate = self
            groundTruthBPSystolic.delegate = self
            groundTruthBPDiastolic.delegate = self
        }

        
        if directoryModel.trialList.count < 3 {
            self.roundDesc.text = directoryModel.POSITIONS[directoryModel.trialList.count] + " round is complete!"
            if (self.restorationIdentifier == "bodyCamSubmit") {
                self.nextButton.setTitle("Next Round", for: UIControlState.normal)
            }
        } else {
            self.roundDesc.text = "Study is complete!"
            if (self.restorationIdentifier == "bodyCamSubmit") {
                self.nextButton.setTitle("Finish", for: UIControlState.normal)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBOutlet weak var roundDesc: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    

    @IBAction func submitRound(_ sender: Any) {
        connectivityManager.send(message: ["action": SUBMIT_RND])
        submit()
    }
    
    @IBAction func onClickHome(_ sender: Any) {
        connectivityManager.send(message: ["action": GO_HOME])
        goHome()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.becomeFirstResponder()
    }
    
    func submit() {
        if directoryModel.phoneMode! == directoryModel.FACE {
            directoryModel.saveFaceTrailRound()
            if directoryModel.trialList.count < 4 {
                directoryModel.saveMetaData()
                DispatchQueue.main.async {
                    let controller = self.storyboard?.instantiateViewController(withIdentifier: "faceCam")
                    self.show(controller!, sender: self)
                }
            } else {
                directoryModel.finishSubjectSession()
                DispatchQueue.main.async {
                    let controller = self.storyboard?.instantiateViewController(withIdentifier: "home")
                    self.show(controller!, sender: self)
                }
            }
        } else {
            let manualEntry = [
                "cardioBuddyBPM": cardioBuddyBPM.text!,
                "pulseOx": ["sp02": pulseOxSp02.text!, "bpm": pulseOxBPM.text!],
                "bloodPressure": [
                    "systolic": groundTruthBPSystolic.text!,
                    "diastolic": groundTruthBPDiastolic.text!
                ],
                "iCare": [
                    "bloodViscosity": iCareBloodViscosity.text!,
                    "pulseOx": iCarePulseOx.text!,
                    "bpm": iCareBPM.text!,
                    "bloodPressure": [
                        "systolic": iCareBPSystolic.text!,
                        "diastolic": iCareBPDiastolic.text!
                    ],
                ]
                ]  as [String : Any]
            
            // need to update trialpostiion, startTime, endTime
            directoryModel.saveBodyTrialRound(manualEntryData: manualEntry)
            if directoryModel.trialList.count < 4 {
                directoryModel.saveMetaData()
                DispatchQueue.main.async {
                    let controller = self.storyboard?.instantiateViewController(withIdentifier: "bodyCam")
                    self.show(controller!, sender: self)
                }
            } else {
                directoryModel.finishSubjectSession()
                bioHarness.disconnect()
                e4.disconnect()
                DispatchQueue.main.async {
                    let controller = self.storyboard?.instantiateViewController(withIdentifier: "home")
                    self.show(controller!, sender: self)
                }
            }
        }
    }
    
    @IBAction func resetSwipe(_ sender: Any) {
        connectivityManager.send(message: ["action": RESET_RND])
        resetRound()
    }
    
    func resetRound() {
        DispatchQueue.main.async {
            let controller = self.storyboard?.instantiateViewController(withIdentifier: self.directoryModel.phoneMode!)
            self.show(controller!, sender: self)
        }
    }
    
    func allFieldsCompleted() {
        if (self.restorationIdentifier == "bodyCamSubmit") {
            if (cardioBuddyBPM.text!.isEmpty || pulseOxBPM.text!.isEmpty || pulseOxSp02.text!.isEmpty || groundTruthBPSystolic.text!.isEmpty || groundTruthBPDiastolic.text!.isEmpty || iCareBPM.text!.isEmpty || iCarePulseOx.text!.isEmpty || iCareBPSystolic.text!.isEmpty || iCareBPDiastolic.text!.isEmpty || iCareBloodViscosity.text!.isEmpty) {
                self.nextButton.isEnabled = false
            } else {
                self.nextButton.isEnabled = true
            }
        }
    }
    
    func goHome() {
        DispatchQueue.main.async {
            let controller = self.storyboard?.instantiateViewController(withIdentifier: "home")
            self.show(controller!, sender: self)
        }
    }
}


extension TrialEndViewController : ConnectivityManagerDelegate {
    func didReceive(message: [String:Any]) {
        switch message["action"] as! String {
        case SUBMIT_RND:
            submit()
        case RESET_RND:
            resetRound()
        case GO_HOME:
            goHome()
        default:
            print("TrialEndViewController was unable to parse message")
        }
    }
    
    func connectedDevicesChanged(manager: ConnectivityManager, connectedDevices: [String]) {
        print("Connections: \(connectedDevices)")
    }
}


