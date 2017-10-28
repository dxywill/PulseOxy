//
//  DirectoryModel.swift
//  Cardiac
//
//  Created by Eileen Guo on 3/29/17.
//  Copyright © 2017 Eileen Guo. All rights reserved.
//

import UIKit

class DirectoryModel {
    let FACE: String = "faceCam"
    let BODY: String = "bodyCam"
    let POSITIONS: [String] = ["supine", "sitting", "sevens", "standing"]
    
    // For Connectivity manager
    let SERVICE_TYPE = "cardiac"
    
    static let sharedInstance = DirectoryModel()
    
    let documentsURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    var rootDirectoryURL: URL
    var subjectDirectoryURL: URL?
    
    var phoneMode: String?
    var subjectData = [String: Any]()
    var trialList = [[String: Any]]()
    
    // Times will be updated if video is recorded
    var trialStartTime = NSDate().timeIntervalSince1970
    var trialEndTime = NSDate().timeIntervalSince1970

    
    var videoFilePath: URL?
    var E4FilePath: URL?
    var BHFilePath: URL?
    var BHCsvText: String = "heartRate,heartRateConfidence,breathingRate,breathingRateConfidence,heartRateVariability,activityLevel,batteryLevel,timestamp\n"
    var E4CsvText: String = "timestamp,type,value\n"
    var metaDataFilePath: URL?
    
    
    init() {
        self.rootDirectoryURL = URL.init(fileURLWithPath: "cardiacData", relativeTo: documentsURL)
        self.E4FilePath = URL.init(fileURLWithPath: "cardiacData", relativeTo: documentsURL)
        self.BHFilePath = URL.init(fileURLWithPath: "cardiacData", relativeTo: documentsURL)
        print(rootDirectoryURL.path)
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: [])
            if directoryContents.count == 0 {
                try FileManager.default.createDirectory(at: rootDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    // starts when demographic data is submitted
    func startBodySession(demographicData: [String:Any], overwriteExistingSession overwrite: Bool = false) -> (success: Bool, error: String)? {
        self.phoneMode = BODY
        self.subjectData["phoneMode"] = BODY
        self.subjectData["subjectID"] = demographicData["subjectID"] as! String
        self.subjectData["demographicData"] = demographicData
        return createSubjectDirectory(directoryName: String(describing: subjectData["subjectID"]!) + String(describing:subjectData["phoneMode"]!), overwriteExistingSession: overwrite)
    }
    
    //Starts when subjectID is submitted
    func startFaceSession(subjectID: String, overwriteExistingSession overwrite: Bool = false) ->
        (success: Bool, error: String)? {
        self.phoneMode = FACE
        self.subjectData["phoneMode"] = FACE
        self.subjectData["subjectID"] = subjectID
        return createSubjectDirectory(directoryName: String(describing: subjectData["subjectID"]!) + String(describing: subjectData["phoneMode"]!), overwriteExistingSession: overwrite)
    }
    
    //Creates subject's root directory (can overwrite previously created directories)
    func createSubjectDirectory(directoryName: String, overwriteExistingSession overwrite: Bool = false)
        -> (success: Bool, error: String)? {
            print("rootDirectoryURL" + rootDirectoryURL.path)
            let newURL = URL.init(fileURLWithPath: "cardiacData/" + directoryName, relativeTo: documentsURL)
            let subjectAlreadyExists = FileManager.default.fileExists(atPath: newURL.path)
            createDirectory: do {
                if subjectAlreadyExists {
                    if overwrite {
                        try FileManager.default.removeItem(at: newURL)
                    } else {
                        print("SubjectID has already been used. Using existing directory")
                        break createDirectory
                    }
                }
                try FileManager.default.createDirectory(at: newURL, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription)
                return (false, "Error creating/deleting directory")
            }
            
            self.subjectDirectoryURL = URL.init(fileURLWithPath: newURL.path)
            self.videoFilePath = URL.init(fileURLWithPath: newURL.path)
            generateMetaDataFileURL()
            return nil
    }
    
    // Saving data from each round (sevens, sitting, standing, etc.) to the trial list
    func saveFaceTrailRound() {
        self.saveE4File()
        let tempDictionary = [
            "startTime": trialStartTime,
            "endTime": trialEndTime,
            "positionType": POSITIONS[trialList.count],
            "faceCamFilePath": videoFilePath!.absoluteString.replacingOccurrences(of: subjectDirectoryURL!.absoluteString, with: ""),
            "E4FilePath": E4FilePath!.absoluteString.replacingOccurrences(of: subjectDirectoryURL!.absoluteString, with: ""),
        ] as [String : Any]
        self.trialList.append(tempDictionary)
        saveMetaData()
    }
    
    func saveBodyTrialRound(manualEntryData manualData: [String:Any]) {
        self.saveBHfile()
        let tempDictionary = [
            "startTime": trialStartTime,
            "endTime": trialEndTime,
            "positionType": POSITIONS[trialList.count],
            "bodyCamFilePath": videoFilePath!.absoluteString.replacingOccurrences(of: subjectDirectoryURL!.absoluteString, with: ""),
            "BHFilePath": BHFilePath!.absoluteString.replacingOccurrences(of: subjectDirectoryURL!.absoluteString, with: ""),
            "manualEntry": manualData
        ] as [String : Any]
        self.trialList.append(tempDictionary)
        saveMetaData()
    }
    
    
    //Saving Subject's MetadataFile
    func finishSubjectSession() {
        saveMetaData()
        resetModel()
    }
    
    func saveMetaData() {
        subjectData["trailList"] = trialList
        do {
            let json = try JSONSerialization.data(withJSONObject: subjectData, options: [JSONSerialization.WritingOptions.prettyPrinted])
            FileManager.default.createFile(atPath: self.metaDataFilePath!.path, contents: json, attributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    func generateMetaDataFileURL() {
        let fileName = String(describing: subjectData["subjectID"]!) + phoneMode! + "MetaData"
        var version = 0
        repeat {
            version += 1
            self.metaDataFilePath = URL.init(fileURLWithPath: fileName + String(version) + ".json", relativeTo: subjectDirectoryURL)
        } while FileManager.default.fileExists(atPath: self.metaDataFilePath!.path)
    }
    
    func generateVideoFileURL() -> (URL){
        let filePath = String(describing: subjectData["subjectID"]!) + POSITIONS[trialList.count] + String(describing: subjectData["phoneMode"]!)
        var version = 0
        repeat {
            version += 1
            self.videoFilePath = URL.init(fileURLWithPath: filePath + String(version) + ".mov", relativeTo: subjectDirectoryURL)
        } while FileManager.default.fileExists(atPath: self.videoFilePath!.path)
        return videoFilePath!
    }
    
    func saveBHfile() {
        let filePath = String(describing: subjectData["subjectID"]!) + POSITIONS[trialList.count] + "BH"
        var version = 0
        repeat {
            version += 1
            self.BHFilePath = URL.init(fileURLWithPath: filePath + String(version) + ".csv", relativeTo: subjectDirectoryURL)
        } while FileManager.default.fileExists(atPath: self.BHFilePath!.path)
        do {
            try BHCsvText.write(to: BHFilePath!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create BH csv file")
            print("\(error)")
        }
        self.BHCsvText = "heartRate,heartRateConfidence,breathingRate,breathingRateConfidence,heartRateVariability,activityLevel,batteryLevel,timestamp\n"
    }
    
    func saveE4File() {
        let filePath = String(describing: subjectData["subjectID"]!) + POSITIONS[trialList.count] + "E4"
        var version = 0
        repeat {
            version += 1
            self.E4FilePath = URL.init(fileURLWithPath: filePath + String(version) + ".csv", relativeTo: subjectDirectoryURL)
        } while FileManager.default.fileExists(atPath: self.E4FilePath!.path)
        do {
            try E4CsvText.write(to: E4FilePath!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create E4 csv file")
            print("\(error)")
        }
        self.E4CsvText = "timestamp,type,value\n"
    }
    
    func resetCsvText() {
        self.BHCsvText = "heartRateConfidence,breathingRate,breathingRateConfidence,heartRateVariability,activityLevel,batteryLevel,timestamp\n"
        self.E4CsvText = "timestamp,type,value\n"
    }
    
    func resetModel() {
        self.BHFilePath = nil
        self.BHCsvText = "heartrate,heartRateConfidence,breathingRate,breathingRateConfidence,heartRateVariability,activityLevel,batteryLevel,timestamp\n"
        self.E4CsvText = "timestamp,type,value\n"
        self.videoFilePath = nil
        self.E4FilePath = nil
        self.subjectDirectoryURL = nil
        self.metaDataFilePath = nil
        self.subjectData = [String: Any]()
        self.trialList = [[String: Any]]()
    }
}

