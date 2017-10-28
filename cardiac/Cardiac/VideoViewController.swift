//
//  VideoViewController.swift
//  Cardiac
//
//  Created by Patrick Leopard on 4/7/17.
//  Copyright © 2017 Eileen Guo. All rights reserved.
//

import UIKit
import AVFoundation

class VideoViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    
    let directoryModel = DirectoryModel.sharedInstance
    let connectivityManager = ConnectivityManager.sharedInstance
    let bioHarness = BioHarness.sharedInstance
    let e4 = E4Controller.sharedInstance
    
    let START_VID = "startVideo"
    let STOP_VID = "stopVideo"
    let SUBMIT_VID = "submitVideo"
    let GO_HOME = "goToHomeScreen"

    @IBOutlet weak var xIcon: UIImageView!
    
    @IBOutlet var BHStatus: [UILabel]!
    
    
    let WHITE_BALANCE_TEMP: Float = 4000.0
    let WHITE_BALANCE_TINT: Float = 0.0
    
    var recordingTimer = Timer()
    var recordingCounter = 0
    
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var positionLabel: UILabel!
    
    lazy var cameraSession: AVCaptureSession = {
        let s = AVCaptureSession()
        return s
    }()
    
    lazy var fileOutput: AVCaptureMovieFileOutput = {
        
        let fileOutput = AVCaptureMovieFileOutput()
        return fileOutput
    }()
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview =  AVCaptureVideoPreviewLayer(session: self.cameraSession)
        preview.bounds = CGRect(x: 0, y: 0, width: self.view.bounds.width/1.5, height: self.view.bounds.height/1.5)
        preview.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
        preview.videoGravity = AVLayerVideoGravity.resize
        return preview
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        updateButtons(isRecording: false)
        
        self.positionLabel.text = directoryModel.POSITIONS[directoryModel.trialList.count]
        connectivityManager.delegate = self
        bioHarness.delegate = self
        e4.delegate = self
        
        if (self.restorationIdentifier == "faceCam") {
            if e4.E4Connected {
                DispatchQueue.main.async {
                    self.xIcon.alpha = 0.0
                }
            } else {
                DispatchQueue.main.async {
                    self.xIcon.alpha = 1.0
                }
            }
        }
        
        setupCameraSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateButtons(isRecording: false)
        
        view.layer.addSublayer(previewLayer)
//        bioHarness.connect()

        
        cameraSession.startRunning()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let device = AVCaptureDevice.default(for: AVMediaType.video) as! AVCaptureDevice
        if (device.torchMode == AVCaptureDevice.TorchMode.on) {
            do {
                try device.lockForConfiguration()
                device.torchMode = AVCaptureDevice.TorchMode.off
                device.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
        bioHarness.disconnect()
    }
    
    // MARK: - Camera Setup
    
    func setupCameraSession() {
        // Default camera and microphone devices
        let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video) as! AVCaptureDevice
        let audioCaptureDevice = AVCaptureDevice.default(for: AVMediaType.audio) as! AVCaptureDevice
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioCaptureDevice)
            
            cameraSession.beginConfiguration()
            
            // Add camera to session
            if cameraSession.canAddInput(videoDeviceInput) {
                cameraSession.addInput(videoDeviceInput)
            } else {
                print("Error: could not add videoDeviceInput.")
            }
            
            // Add microphone to session
            if cameraSession.canAddInput(audioDeviceInput) {
                cameraSession.addInput(audioDeviceInput)
            } else {
                print("Error: could not add audioDeviceInput.")
            }
            
            // Add file output to session
            if cameraSession.canAddOutput(fileOutput) {
                cameraSession.addOutput(fileOutput)
            } else {
                print("Error: could not add device output.")
            }
            
            configureCameraWhiteBalance(device: videoCaptureDevice)
            
            // Set camera to highest available framerate
            configureCameraForHighestFrameRate(device: videoCaptureDevice)
            
            if directoryModel.subjectData["phoneMode"] as! String == directoryModel.BODY {
                configureTorch(device: videoCaptureDevice, torchLevel: 0.1)
            }
            
            
            cameraSession.commitConfiguration()
        }
        catch let error as NSError {
            print("\(error): \(error.localizedDescription)")
        }
    }
    
    func configureCameraForHighestFrameRate(device: AVCaptureDevice) {
        // Load formats that camera is capable of
        let deviceFormats = device.formats 
        var bestFormat = deviceFormats[0]
        
        if var bestFrameRateRange: AVFrameRateRange = bestFormat.videoSupportedFrameRateRanges[0] as? AVFrameRateRange {
            
            // Loop through device formats and find highest framerate and format available
            for format in deviceFormats {
                for range in format.videoSupportedFrameRateRanges as! [AVFrameRateRange] {
                    
                    // Check if new highest
                    if range.maxFrameRate > bestFrameRateRange.maxFrameRate {
                        bestFormat = format
                        bestFrameRateRange = range
                    }
                }
            }
            
            // Configure device
            do{
                try device.lockForConfiguration()
                
                // Set camera properties
                device.activeFormat = bestFormat
                device.activeVideoMinFrameDuration = bestFrameRateRange.minFrameDuration
                device.activeVideoMaxFrameDuration = bestFrameRateRange.minFrameDuration
                
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device to configure camera frame rate.")
            }
            
        } else {
            print("Error: Could not cast \"var bestFrameRateRange\" as \"AVFrameRateRange\".")
        }
    }
    
    func configureCameraWhiteBalance(device: AVCaptureDevice) {
        // Configure device
        do{
            try device.lockForConfiguration()
            
            // Set white balance to 4000 K and 0 tint
            let temperatureAndTintValues = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: WHITE_BALANCE_TEMP, tint: WHITE_BALANCE_TINT)
            var deviceGains = device.deviceWhiteBalanceGains(for: temperatureAndTintValues)
            deviceGains = setGainsRange(gains: deviceGains, device: device)
            device.setWhiteBalanceModeLocked(with: deviceGains, completionHandler: nil)
            
            device.unlockForConfiguration()
        } catch {
            print("Could not lock device to configure camera white balance.")
        }
    }
    
    func configureTorch(device: AVCaptureDevice, torchLevel: Float) {
        // Configure device
        do{
            try device.lockForConfiguration()
            
            try device.setTorchModeOn(level: torchLevel)
            
            device.unlockForConfiguration()
        } catch {
            print("Could not lock device to configure torch.")
        }
    }
    
    func setGainsRange(gains: AVCaptureDevice.WhiteBalanceGains, device: AVCaptureDevice) -> AVCaptureDevice.WhiteBalanceGains {
        var ng = gains
        
        ng.redGain = max(1.0, ng.redGain)
        ng.greenGain = max(1.0, ng.greenGain)
        ng.blueGain = max(1.0, ng.blueGain)
        
        ng.redGain = min(device.maxWhiteBalanceGain, ng.redGain)
        ng.greenGain = min(device.maxWhiteBalanceGain, ng.greenGain)
        ng.blueGain = min(device.maxWhiteBalanceGain, ng.blueGain)
        
        return ng
    }
    
    func beginRecording() {
        // Save file in Documents directory
        let fileURL = directoryModel.generateVideoFileURL()
        
        fileOutput.startRecording(to: fileURL, recordingDelegate: self)
    }
    
    func endRecording() {
        fileOutput.stopRecording()
    }
    
    // MARK: - Actions
    @IBAction func submitVideo(_ sender: Any) {
        connectivityManager.send(message: ["action": SUBMIT_VID])
        submit()
    }
    
    @IBAction func pushRecord(_ sender: Any) {
        connectivityManager.send(message: ["action": START_VID])
        startVideoRecording()
    }
    
    @IBAction func pushStop(_ sender: Any) {
        connectivityManager.send(message: ["action": STOP_VID])
        stopVideoRecording()
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("hello");
    }
    
    // Informs the delegate when the output has started writing to a file
    func capture(_: AVCaptureFileOutput!, didStartRecordingToOutputFileAt: URL!, fromConnections: [Any]!) {
        print("didStartRecordingToOutputFileAt: \(didStartRecordingToOutputFileAt!)")
    }

    // Informs the delegate when the output will stop writing new samples to a file
    func capture(_: AVCaptureFileOutput!, willFinishRecordingToOutputFileAt: URL!, fromConnections: [Any]!, error: Error!) {
        print("willFinishRecordingToOutputFileAt: \(willFinishRecordingToOutputFileAt!)")
    }
    
    // Required. Informs the delegate when all pending data has been written to an output file
    func capture(_: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt: URL!, fromConnections: [Any]!, error: Error!) {
        print("didFinishRecordingToOutputFileAt: \(didFinishRecordingToOutputFileAt!)")
    }
    
    // Called whenever the output is recording to a file and successfully pauses the recording at the request of a client
    func capture(_: AVCaptureFileOutput!, didPauseRecordingToOutputFileAt: URL!, fromConnections: [Any]!) {
        print("didPauseRecordingToOutputFileAt: \(didPauseRecordingToOutputFileAt!)")
    }
    
    // Called whenever the output, at the request of the client, successfully resumes a file recording that was paused
    func capture(_: AVCaptureFileOutput!, didResumeRecordingToOutputFileAt: URL!, fromConnections: [Any]!) {
        print("didResumeRecordingToOutputFileAt: \(didResumeRecordingToOutputFileAt!)")
    }
    
    // MARK: - Timer
    
    func startTimer() {
        recordingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(VideoViewController.updateTimer), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        recordingTimer.invalidate()
        recordingCounter = 0
        timerLabel.text = "00:00"
    }
    
    @objc func updateTimer() {
        recordingCounter += 1
        
        let minutes = Int(recordingCounter) / 60 % 60
        let seconds = Int(recordingCounter) % 60
        
        // Format as "00:00"
        timerLabel.text = String(format:"%02i:%02i", minutes, seconds)
    }
    
    // MARK: - Miscellaneous
    
    func updateButtons(isRecording: Bool) {
        // Update button appearances
        if (self.restorationIdentifier == "faceCam") {
            DispatchQueue.main.async {
                self.recordButton.isEnabled = !isRecording
                self.stopButton.isEnabled = isRecording
            }
        }
    }
    
    // MARK: - Connectivity Manager Action Functions
    
    func startVideoRecording() {
        DispatchQueue.main.async {
            self.directoryModel.trialStartTime = NSDate().timeIntervalSince1970
            self.beginRecording()
            
            self.startTimer()
            self.updateButtons(isRecording: true)
        }
    }
    
    func stopVideoRecording() {
        DispatchQueue.main.async {
            self.directoryModel.trialEndTime = NSDate().timeIntervalSince1970
            self.endRecording()
            
            self.stopTimer()
            self.updateButtons(isRecording: false)
        }
    }
    
    func submit() {
        let device = AVCaptureDevice.default(for: AVMediaType.video) as! AVCaptureDevice
        if (device.torchMode == AVCaptureDevice.TorchMode.on) {
            do {
                try device.lockForConfiguration()
                device.torchMode = AVCaptureDevice.TorchMode.off
                device.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
//        bioHarness.disconnect()
        
        DispatchQueue.main.async {
            let controller = self.storyboard?.instantiateViewController(withIdentifier: self.directoryModel.phoneMode! + "Submit")
            self.show(controller!, sender: self)
        }
    }
    
    
    @IBAction func toggleDeviceConnection(_ sender: Any) {
        if directoryModel.phoneMode == directoryModel.FACE {
            if e4.E4Connected {
                e4.disconnect()
            } else {
                e4.connect()
            }
        } else {
            if bioHarness.zephyrConnected {
                bioHarness.disconnect()
            } else {
                bioHarness.connect()
            }
        }
    }
    
    @IBAction func onClickHome(_ sender: Any) {
        connectivityManager.send(message: ["action": GO_HOME])
        goHome()
    }
    
    func goHome() {
        DispatchQueue.main.async {
            let controller = self.storyboard?.instantiateViewController(withIdentifier: "home")
            self.show(controller!, sender: self)
        }
    }
    
}

extension VideoViewController: ConnectivityManagerDelegate {
    func didReceive(message: [String:Any]) {
        switch message["action"] as! String {
        case START_VID:
            print("VideoViewController: Starting Video")
            startVideoRecording()
        case STOP_VID:
            stopVideoRecording()
            print("VideoViewController: Stopping video")
        case SUBMIT_VID:
            submit()
            print("VideoViewController: Submitting video")
        case GO_HOME:
            goHome()
        default:
            print("VideoViewController: Unable to parse received message")
        }
    }
    
    func connectedDevicesChanged(manager: ConnectivityManager, connectedDevices: [String]) {
        print("Connections: \(connectedDevices)")
    }
}

extension VideoViewController: BHDelegate, E4ControllerDelegate {
    func showAlert(alert: UIAlertController) {
        self.present(alert, animated: true, completion: nil)
    }
    func updateStatusCodes(codes: Dictionary<String, Any>) {
        var enableRecord = true
        for label in BHStatus {
            switch label.text! {
            case "HR":
                if codes["heartRateReliable"] as! String == "Yes" {
                    label.backgroundColor = UIColor.green
                } else {
                    label.backgroundColor = UIColor.red
                    enableRecord = false
                }
            case "HRV":
                if codes["heartRateVariabilityReliable"] as! String == "Yes" {
                    label.backgroundColor = UIColor.green
                } else {
                    label.backgroundColor = UIColor.red
                }
            case "BR":
                if codes["breatingRateReliable"] as! String == "Yes" {
                    label.backgroundColor = UIColor.green
                } else {
                    label.backgroundColor = UIColor.red
                    enableRecord = false
                }
            case "DW":
                if codes["deviceWornDetectionLevel"] as! String == "Full Confidence" {
                    label.backgroundColor = UIColor.green
                } else {
                    label.backgroundColor = UIColor.red
                    enableRecord = false
                }
            default:
                print("VideoViewController: Unable to parse Bio Harness Status code")
            }
        }
        
        if (self.restorationIdentifier == "faceCam") {
            DispatchQueue.main.async {
                self.recordButton.isEnabled = enableRecord
            }
        }
        DispatchQueue.main.async {
            self.xIcon.alpha = 0.0
        }
    }
    func updateIcon(connected: Bool) {
        if (connected) {
            DispatchQueue.main.async {
                self.xIcon.alpha = 0.0
            }
        } else {
            DispatchQueue.main.async {
                self.xIcon.alpha = 1.0
            }
        }
    }
}

