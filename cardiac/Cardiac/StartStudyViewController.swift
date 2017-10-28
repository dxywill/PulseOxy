//
//  DemSurveyViewController.swift
//  Cardiac
//
//  Created by Eileen Guo on 3/21/17.
//  Copyright © 2017 Eileen Guo. All rights reserved.
//

import Foundation
import UIKit

class StartStudyViewController: UIViewController, UITextFieldDelegate {
    
    let directoryModel = DirectoryModel.sharedInstance
    let connectivityManager = ConnectivityManager.sharedInstance
    let bioHarness = BioHarness.sharedInstance
    let e4 = E4Controller.sharedInstance
    var initiationPhone = [String: String]()
    let INITIATE_EXP = "initiateExperiment"
    let START_EXP = "startExperiment"
    let GO_HOME = "goToHomeScreen"
    
    @IBOutlet weak var connectE4: UIButton!
    @IBOutlet weak var authE4: UIButton!
    @IBOutlet weak var watchIcon: UIImageView!
    @IBOutlet weak var authActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var connectActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var StudyID: UITextField!
    @IBOutlet weak var Gender: UISegmentedControl!
    @IBOutlet weak var Age: UITextField!
    @IBOutlet weak var HeightFt: UITextField!
    @IBOutlet weak var HeightIn: UITextField!
    @IBOutlet weak var Weight: UITextField!
    @IBOutlet weak var DominantSide: UISegmentedControl!
    @IBOutlet weak var HeartCondition: UISwitch!
    @IBOutlet weak var LungCondition: UISwitch!
    @IBOutlet weak var Medication: UISwitch!
    @IBOutlet weak var Activity: UISegmentedControl!
    
    @IBOutlet weak var Bicycle: UISwitch!
    @IBOutlet weak var Calisthenics: UISwitch!
    @IBOutlet weak var Jog: UISwitch!
    @IBOutlet weak var LiftWeigts: UISwitch!
    @IBOutlet weak var Swim: UISwitch!
    @IBOutlet weak var Walk: UISwitch!
    @IBOutlet weak var OtherExercise: UISwitch!
    @IBOutlet weak var OtherExerciseDescription: UITextField!
    
    
    @IBOutlet weak var Ethnicity: UISegmentedControl!
    
    @IBOutlet weak var Black: UISwitch!
    @IBOutlet weak var AmericanIndian: UISwitch!
    @IBOutlet weak var NativeHawaiian: UISwitch!
    @IBOutlet weak var White: UISwitch!
    @IBOutlet weak var Asian: UISwitch!
    @IBOutlet weak var OtherRace: UISwitch!
    @IBOutlet weak var OtherRaceDescription: UITextField!
    
    @IBOutlet weak var Smoke: UISegmentedControl!
    @IBOutlet weak var Alcohol: UISegmentedControl!
    
    @IBOutlet weak var SubmitButton: UIButton!
    @IBOutlet weak var submitActivityIndicator: UIActivityIndicatorView!

    
    @IBAction func screenTapped(_ sender: Any) {
        UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil);
        allFieldsCompleted()
    }

    @IBAction func onAuthE4(_ sender: Any) {
        self.authE4.isEnabled = false
        e4.authenticate()
        authActivityIndicator.startAnimating()
    }
    @IBAction func onConnectE4(_ sender: Any) {
        e4.connect()
        connectActivityIndicator.startAnimating()
    }
    
    @IBAction func onClickHome(_ sender: Any) {
        connectivityManager.send(message: ["action": GO_HOME])
        goHome()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        connectivityManager.delegate = self
        e4.delegate = self
        e4.connectDelegate = self
        
        if self.restorationIdentifier == "bodyCamStart" {
            bioHarness.connect()
        }
        
        if e4.apiConnected {
            DispatchQueue.main.async {
                self.authE4.isEnabled = false
                self.connectE4.isEnabled = true
            }
            if e4.E4Connected {
                DispatchQueue.main.async {
                    self.connectE4.isEnabled = false
                    self.watchIcon.alpha = 1.0
                }
            }
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func allFieldsCompleted() {
        if (self.restorationIdentifier != "faceCamStart") {
            if (StudyID.text!.isEmpty || Age.text!.isEmpty || HeightFt.text!.isEmpty || HeightIn.text!.isEmpty || Weight.text!.isEmpty) {
                self.SubmitButton.isEnabled = false
            } else {
                if (!initiationPhone.isEmpty || e4.E4Connected) {
                    if (initiationPhone["subjectID"] == StudyID.text!) {
                        self.SubmitButton.isEnabled = true
                    } else {
                        self.SubmitButton.isEnabled = false
                    }
                } else {
                    self.SubmitButton.isEnabled = true
                }
            }
        } else {
            if (StudyID.text!.isEmpty) {
                self.SubmitButton.isEnabled = false
            } else {
                if (!initiationPhone.isEmpty) {
                    if (initiationPhone["subjectID"] == StudyID.text!) {
                        self.SubmitButton.isEnabled = true
                    } else {
                        self.SubmitButton.isEnabled = false
                    }
                } else {
                    self.SubmitButton.isEnabled = true
                }
            }
        }
    }
    
    @IBAction func submitData(_ sender: Any) {
        submitActivityIndicator.startAnimating()
        if (self.restorationIdentifier == "faceCamStart") {
            let failed = directoryModel.startFaceSession(subjectID: StudyID.text!)
            if failed != nil {
                print(failed!.error)
            } else {
                handleExperimentStart()
            }
        } else {
            let exercizes = ["bicycle": Bicycle.isOn, "calisthenics": Calisthenics.isOn, "jog": Jog.isOn, "liftWeights": LiftWeigts.isOn, "swim": Swim.isOn, "walk": Walk.isOn, "otherExercise": OtherExercise.isOn, "otherExerciseDescription": OtherExerciseDescription.text!] as [String : Any]
            let race = ["black": Black.isOn, "americanIndian": AmericanIndian.isOn, "nativeHawaiian": NativeHawaiian.isOn, "white": White.isOn, "asian": Asian.isOn, "otherRace": OtherRace.isOn, "otherRaceDescription": OtherRaceDescription.text!] as [String : Any]
            let demographicData = [
                "subjectID": StudyID.text!,
                "gender": Gender.titleForSegment(at: Gender.selectedSegmentIndex)!,
                "age": Age.text!,
                "height": [
                    "ft": HeightFt.text!,
                    "in": HeightIn.text!
                ],
                "weight": Weight.text!,
                "dominantSide": DominantSide.titleForSegment(at: DominantSide.selectedSegmentIndex)!,
                "heartCondition": HeartCondition.isOn,
                "lungCondition": LungCondition.isOn,
                "medication": Medication.isOn,
                "activityAmount": Activity.titleForSegment(at: Activity.selectedSegmentIndex)!,
                "activities": exercizes,
                "ethnicity": Ethnicity.titleForSegment(at: Ethnicity.selectedSegmentIndex)!,
                "race": race,
                "smoking": Smoke.titleForSegment(at: Smoke.selectedSegmentIndex)!,
                "alcoholConsumption": Alcohol.titleForSegment(at: Alcohol.selectedSegmentIndex)!
                ] as [String : Any]
            print(demographicData)
            let failed = directoryModel.startBodySession(demographicData: demographicData)
            if failed != nil {
                print(failed!.error)
            } else {
                handleExperimentStart()
            }
        }
    }
    
    func startExperiment() {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: directoryModel.phoneMode!)
        DispatchQueue.main.async {
            self.show(controller!, sender: self)
        }
    }
    
    func handleExperimentStart() {
        if (!initiationPhone.isEmpty) {
            connectivityManager.send(message: ["action": START_EXP])
            startExperiment()
        } else {
            connectivityManager.send(message: ["action": INITIATE_EXP, "subjectID": StudyID.text!])
            self.SubmitButton.isEnabled = false
        }
    }
    
    func handleExperimentInitiation(subjectID: String) {
        self.initiationPhone = ["subjectID": subjectID]

        if (subjectID == StudyID.text!) {
            DispatchQueue.main.async {
                self.SubmitButton.isEnabled = true
            }
        } else {
            DispatchQueue.main.async {
                self.SubmitButton.isEnabled = false
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

extension StartStudyViewController: ConnectivityManagerDelegate {
    func didReceive(message: [String:Any]) {
        switch message["action"] as! String {
        case INITIATE_EXP:
            handleExperimentInitiation(subjectID: message["subjectID"] as! String)
        case START_EXP:
            startExperiment()
            print("StartStudyViewController: Starting experiment")
        case GO_HOME:
            goHome()
        default:
            print("StartStudyViewController: unable to parse message")
        }
    }
    
    func connectedDevicesChanged(manager: ConnectivityManager, connectedDevices: [String]) {
        print("Connections: \(connectedDevices)")
    }
}

extension StartStudyViewController: E4ControllerDelegate, E4ConnectDelegate {
    func updateIcon(connected: Bool) {
        if (connected) {
            DispatchQueue.main.async {
                self.connectE4.isEnabled = false
                self.watchIcon.alpha = 1.0
                self.connectActivityIndicator.stopAnimating()
            }
        } else {
            DispatchQueue.main.async {
                self.watchIcon.alpha = 0.0
                self.connectActivityIndicator.stopAnimating()
            }
        }
    }
    func authSuccess(authenticated: Bool) {
        if authenticated {
            DispatchQueue.main.async {
                self.connectE4.isEnabled = true
                self.authActivityIndicator.stopAnimating()
            }
        } else {
            DispatchQueue.main.async {
                self.connectE4.isEnabled = false
                self.authE4.isEnabled = true
                self.authActivityIndicator.stopAnimating()
            }
        }
    }
}
