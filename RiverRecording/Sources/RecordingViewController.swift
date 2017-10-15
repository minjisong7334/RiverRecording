//
//  ViewController.swift
//  RiverRecording
//
//  Created by Marquez Kim on 2016. 7. 26..
//  Copyright © 2016년 Marquez Kim. All rights reserved.
//

import UIKit
import AVFoundation 

class RecordingViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // UI part
    @IBOutlet var recBtn: UIButton!
    @IBOutlet var playBtn: UIButton!
    
    // AV part
    var recorder:AVAudioRecorder!
    var player:AVAudioPlayer!
    var captureSession:AVCaptureSession!
    var captureDevice:AVCaptureDevice!
    var previewLayer:AVCaptureVideoPreviewLayer!
    
    var meterTimer:Timer!
    
    var soundFileURL:URL!
    
    var isRecording:Bool!
    var isPlaying:Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Boolean set up
        isRecording = false
        isPlaying = false
        
        // AV init
        setSessionPlayback()
        askForNotifications()
        checkHeadphones()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        recorder = nil
        player = nil
    }
    
// MARK: Record
    
    @IBAction func pressRecBtn(_ sender: UIButton) {
        print("rec btn pressed")
        // UI change
        isRecording = !isRecording
        
        if isRecording == true { // Recording Stop
            record()
        } else {
            stop()
        }
    }
    
    func record() {
        // AV
        // check player
        if player != nil && player.isPlaying {
            player.stop()
        } else {
            // do nothing
        }
        
        // Recorder
        if recorder == nil {
            print("recording, recorder nil")
            recordWithPermission(true)
            return
        } else {
            if recorder.isRecording {
                print("pausing")
                recorder.pause()
            } else {
                print("recording")
                recordWithPermission(false)
            }
        }
    }
    
    func recordWithPermission(_ setup:Bool) {
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        // ios 8 and later
        if (session.responds(to: #selector(AVAudioSession.requestRecordPermission(_:)))) {
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    print("Permission to record granted")
                    self.setSessionPlayAndRecord()
                    if setup {
                        self.setupRecorder()
                    }
                    self.recorder.record()
//                    self.meterTimer = Timer.scheduledTimer(timeInterval: 0.1,
//                        target:self,
//                        selector:#selector(RecordingViewController.updateAudioMeter(_:)),
//                        userInfo:nil,
//                        repeats:true)
                } else {
                    print("Permission to record not granted")
                }
            })
        } else {
            print("requestRecordPermission unrecognized")
        }
    }
    
    func setupRecorder() {
        let format = DateFormatter()
        format.dateFormat="yyyy-MM-dd-HH-mm-ss"
        let currentFileName = "recording-\(format.string(from: Date())).m4a"
        print(currentFileName)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.soundFileURL = documentsDirectory.appendingPathComponent(currentFileName)
        
        let prefs = UserDefaults.standard
        prefs.set(self.soundFileURL, forKey: "Record")
        prefs.synchronize()
        
        if FileManager.default.fileExists(atPath: soundFileURL.absoluteString) {
            // probably won't happen. want to do something about it?
            print("soundfile \(soundFileURL.absoluteString) exists")
        }
        
        let recordSettings:[String : AnyObject] = [
            AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC as UInt32),
            AVEncoderAudioQualityKey : AVAudioQuality.min.rawValue as AnyObject,
            AVNumberOfChannelsKey: 1 as AnyObject,
            AVSampleRateKey : 12000.0 as AnyObject
        ]
        
        do {
            recorder = try AVAudioRecorder(url: soundFileURL, settings: recordSettings)
            recorder.delegate = self
            recorder.isMeteringEnabled = true
            recorder.prepareToRecord() // creates/overwrites the file at sound as! AVAudioRecorderDelegateFileURL
        } catch let error as NSError {
            recorder = nil
            print(error.localizedDescription)
        }
        
    }
    
    func setSessionPlayAndRecord() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
        } catch let error as NSError {
            print("could not set session category")
            print(error.localizedDescription)
        }
        
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print("could not make session active")
            print(error.localizedDescription)
        }
    }
    
    
    func stop() {
        print("stop")
        
        recorder?.stop()
        player?.stop()
        
        //meterTimer.invalidate()

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false)
        } catch let error as NSError {
            print("could not make session inactive")
            print(error.localizedDescription)
        }
        
        recorder = nil
    }
    
    func setSessionPlayback() {
        let session:AVAudioSession = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
        } catch let error as NSError {
            print("Fail: set session category")
            print(error.localizedDescription)
        }
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print("Fail: make session active")
            print(error.localizedDescription)
        }
    }

    func askForNotifications() {

        NotificationCenter.default.addObserver(self,
                                               selector:#selector(RecordingViewController.background(_:)),
                                               name:NSNotification.Name.UIApplicationWillResignActive,
                                               object:nil)

        NotificationCenter.default.addObserver(self,
                                               selector:#selector(RecordingViewController.foreground(_:)),
                                               name:NSNotification.Name.UIApplicationWillEnterForeground,
                                               object:nil)

        NotificationCenter.default.addObserver(self,
                                               selector:#selector(RecordingViewController.routeChange(_:)),
                                               name:NSNotification.Name.AVAudioSessionRouteChange,
                                               object:nil)
    }

    @objc func background(_ notification:Notification) {
        print("background")
    }

    @objc func foreground(_ notification:Notification) {
        print("foreground")
    }


    @objc func routeChange(_ notification:Notification) {
        print("routeChange \(String(describing: (notification as NSNotification).userInfo))")

        if let userInfo = (notification as NSNotification).userInfo {
            //print("userInfo \(userInfo)")
            if let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt {
                //print("reason \(reason)")
                switch AVAudioSessionRouteChangeReason(rawValue: reason)! {
                case AVAudioSessionRouteChangeReason.newDeviceAvailable:
                    print("NewDeviceAvailable")
                    print("did you plug in headphones?")
                    checkHeadphones()
                case AVAudioSessionRouteChangeReason.oldDeviceUnavailable:
                    print("OldDeviceUnavailable")
                    print("did you unplug headphones?")
                    checkHeadphones()
                case AVAudioSessionRouteChangeReason.categoryChange:
                    print("CategoryChange")
                case AVAudioSessionRouteChangeReason.override:
                    print("Override")
                case AVAudioSessionRouteChangeReason.wakeFromSleep:
                    print("WakeFromSleep")
                case AVAudioSessionRouteChangeReason.unknown:
                    print("Unknown")
                case AVAudioSessionRouteChangeReason.noSuitableRouteForCategory:
                    print("NoSuitableRouteForCategory")
                case AVAudioSessionRouteChangeReason.routeConfigurationChange:
                    print("RouteConfigurationChange")

                }
            }
        }

    }

    func checkHeadphones() {
        // check NewDeviceAvailable and OldDeviceUnavailable for them being plugged in/unplugged
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        if currentRoute.outputs.count > 0 {
            for description in currentRoute.outputs {
                if description.portType == AVAudioSessionPortHeadphones {
                    print("headphones are plugged in")
                    break
                } else {
                    print("headphones are unplugged")
                }
            }
        } else {
            print("checking headphones requires a connection to a device")
        }
    }
    
    //MARK: Play
    @IBAction func pressPlayBtn(_ sender: UIButton) {
        
        isPlaying = !isPlaying
        
        if (!isPlaying) {
            play()
//            player.play()
        } else {
            stop()
//            player.stop()
        }
    }
    
    func play() {
        
        
        do {
            let prefs = UserDefaults.standard
            let url = prefs.url(forKey: "Record")
            try player = AVAudioPlayer(contentsOf: url!)
            player.delegate = self
            player.play()
        } catch {
            print("Audioplayer error: \(error.localizedDescription)")
        }
        
    }
}

// MARK: AVAudioRecorderDelegate
extension RecordingViewController : AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder,
                                         successfully flag: Bool) {
        print("finished recording \(flag)")
        
        // iOS8 and later
        let alert = UIAlertController(title: "Recorder",
                                      message: "Finished Recording",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Make", style: .default, handler: {action in
            print("Make was tapped")
            
            
        }))
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: {action in
            print("delete was tapped")
            self.recorder.deleteRecording()
        }))
        self.present(alert, animated:true, completion:nil)
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder,
                                          error: Error?) {
        
        if let e = error {
            print("\(e.localizedDescription)")
        }
    }
}


//
//// MARK: AVAudioPlayerDelegate
extension RecordingViewController : AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("finished playing \(flag)")
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let e = error {
            print("\(e.localizedDescription)")
        }
        
    }
}

