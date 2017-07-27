//
//  VoiceVC.swift
//  TranslateThisV2
//
//  Created by Ruben Duran on 7/27/17.
//  Copyright © 2017 R&R Developement. All rights reserved.
//

import Speech
import AVFoundation
import Foundation
import UIKit


class VoiceVC: UIViewController, SFSpeechRecognizerDelegate {
    
    //Variables and Outlets
    
    @IBOutlet weak var menuBtn: UIBarButtonItem!
    @IBOutlet weak var textBtn: UIBarButtonItem!
    
    @IBOutlet weak var pickerView: UIPickerView!
    
    
    @IBOutlet weak var spokenTextLabel: UILabel!
    @IBOutlet weak var translatedTextLabel: UILabel!
    
    
    @IBOutlet weak var recordBtn: UIButton!
    @IBOutlet weak var saveBtn: UIButton!

    var languages = ["Spanish", "Korean", "Portuguese", "English"]
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var audioPlayer: AVAudioPlayer!
    var recording = false
    
    
    
    //Button Actions
    
    @IBAction func recordBtnPressed(_ sender: UIButton) {

        print("record pressed")
        if recording {
            audioEngine.stop()
            if let node = audioEngine.inputNode {
                node.removeTap(onBus: 0)
            }
            recognitionTask?.cancel()
            recordBtn.backgroundColor = UIColor.red
            recording = false
        } else if !recording {
            self.recordAndRecognizeSpeech()
            recordBtn.backgroundColor = UIColor.green
            recording = true
        }

    }
    
    @IBAction func saveBtnPressed(_ sender: UIButton) {
        print("save pressed")
    }
    
    
    
    // Slide Menu Functions
    
    func sideMenu() {
        if revealViewController() != nil {
            menuBtn.target = revealViewController()
            menuBtn.action = #selector(SWRevealViewController.revealToggle(_:))
            revealViewController().rearViewRevealWidth = 175
            
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
    }
    
    
    
    
    //UIPicker info
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return languages.count;
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return languages[row] as String
        
    }
    
    //General
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sideMenu()
        self.pickerView.dataSource = self as? UIPickerViewDataSource
        self.pickerView.delegate = self as? UIPickerViewDelegate
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    //Voice Functions
    
    func recordAndRecognizeSpeech() {
        guard let node = audioEngine.inputNode else { return }
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            buffer, _ in self.request.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try  audioEngine.start()
            print("It Started")
            
        } catch {
            return print(error)
        }
        
        guard let myRecognizer = SFSpeechRecognizer() else {
            print("damn")
            return
        }
        if !myRecognizer.isAvailable {
            print("nope")
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: {
            result, error in
            if let result = result {
                print("in task")
                let bestString = result.bestTranscription.formattedString
                self.spokenTextLabel.text = bestString
                print("wtf")
                self.translate(text: bestString)
            } else if let error = error {
                print(error)
                print("the errors")
            }
        })
        print("It stopped")
        
    }
    
    func translate(text:String?) -> String {
        if let toBeTranaslated = text {
            let newToBeTranslated = toBeTranaslated.replacingOccurrences(of: " ", with: "+")
            let languaged = "es"
            print(newToBeTranslated)
            let url = URL(string: "https://translation.googleapis.com/language/translate/v2?key=AIzaSyCxfmolIMWqxSLSJZXvBCkT1gmNKrbDRvQ&q=" + newToBeTranslated + "&target=" + languaged)
            // create a URLSession to handle the request tasks
            let session = URLSession.shared
            // create a "data task" to make the request and run completion handler
            let task = session.dataTask(with: url!, completionHandler: {
                // see: Swift closure expression syntax
                data, response, error in
                // data -> JSON data, response -> headers and other meta-information, error-> if one occurred
                // "do-try-catch" blocks execute a try statement and then use the catch statement for errors
                do {
                    // try converting the JSON object to "Foundation Types" (NSDictionary, NSArray, NSString, etc.)
                    if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                        print(jsonResult)
                        let data = jsonResult["data"] as! NSDictionary
                        print(data)
                        let transl = data["translations"] as! NSArray
                        let translationDict = transl[0] as! NSDictionary
                        let translatedText = translationDict["translatedText"] as! String
                        print(translatedText)
                        DispatchQueue.main.async {
//                            self.passedIn.text = ("Phrase: \(self.thePhrase.text!)")
                            self.translatedTextLabel.text = ("Translation: \(translatedText)")
//                            self.thePhrase.text = ""
                        }
                        
                    }
                } catch {
                    print(error)
                }
            })
            // execute the task and then wait for the response
            // to run the completion handler. This is async!
            task.resume()
            
        } else {
            print("Please write a valid word")
        }
        return translatedTextLabel.text!
    }
    
}
