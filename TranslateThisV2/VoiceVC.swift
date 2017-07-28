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


class VoiceVC: UIViewController, SFSpeechRecognizerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    //Variables and Outlets
    
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var spokenTextLabel: UILabel!
    @IBOutlet weak var translatedTextLabel: UILabel!
    @IBOutlet weak var recordBtnVisual: UIButton!
    
    var languages = ["Spanish", "Korean", "Portuguese", "English"]
    var language = "es"
    var voice = "es-MX"
    var transText = ""
    var pickerIdx = 0
    var username: String?
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    let synthesizer = AVSpeechSynthesizer()
    var recording = false
    
    //Buttons
    
    @IBAction func recordBtn(_ sender: UIButton) {
        print("record pressed")
        if recording {
            audioEngine.stop()
            if let node = audioEngine.inputNode {
                node.removeTap(onBus: 0)
            }
            recognitionTask?.cancel()
            sender.setImage(#imageLiteral(resourceName: "mic_logo"), for: UIControlState.normal)
            recording = false
        } else if !recording {
            recordAndRecognizeSpeech()
            sender.setImage(#imageLiteral(resourceName: "mic_rec_logo"), for: UIControlState.normal)
            recording = true
        }
    }
    
    @IBAction func saveBtn(_ sender: UIButton) {
        print("save pressed")
        let newPhrase = spokenTextLabel.text
        let newTrans = translatedTextLabel.text
        let user = username!
        
        var user_id: Int?
        var translated_lang: String?
        translated_lang = voice
        
        
        let userAPI = "http://13.59.119.156/users/"
        let phraseAPI = "http://13.59.119.156/phrases/"
        
        getRequestSession(urlStr: userAPI, completionHandler: {
            data, response, error in
            print("Data: \(String(describing: data))")
            print("Response: \(String(describing: response))")
            print("Error: \(String(describing: error))")
            
            do {
                if let requestResults = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSArray {
                    var userExists = false
                    for object in requestResults {
                        let currUsers = object as! NSDictionary
                        if currUsers["username"] as? String == user {
                            if let newUser = currUsers["id"] {
                                user_id = newUser as? Int
                            }
                            userExists = true
                            break
                        }
                    }
                    
                    if userExists == true {
                        
                        self.postPhraseRequestSession(urlStr: phraseAPI, user_id: user_id!, newPhrase: newPhrase!, newTrans: newTrans!, translated_lang: translated_lang!, completionHandler: {
                            data, response, error in
                            do {
                                
                                if let requestResults = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSArray {
                                }
                            } catch { print(error) }
                        })
                        
                    }
                    else {
                        self.postRequestSession(urlStr: userAPI, username: user, completionHandler: {
                            data, respones, error in
                            
                            do {
                                if let userData = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                                    if let newUser = userData["id"] {
                                        user_id = newUser as? Int
                                    }
                                    self.postPhraseRequestSession(urlStr: phraseAPI, user_id: user_id!, newPhrase: newPhrase!, newTrans: newTrans!, translated_lang: translated_lang!,  completionHandler: {
                                        data, resones, error in
                                        
                                        do {
                                            if let requestResults = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSArray {
                                            }
                                        } catch { print(error) }
                                    })
                                }
                            } catch { print(error) }
                        })
                    }
                }
            } catch { print(error) }
        })
        self.spokenTextLabel.text = nil
        self.translatedTextLabel.text = "Saved"
    }
    
    @IBAction func playBtn(_ sender: UIButton) {
        if pickerView.selectedRow(inComponent: 0) == pickerIdx {
            speak(string: translatedTextLabel.text!, language: voice)
        } else{
            translate(text: spokenTextLabel.text)
            sleep(1)
            self.speak(string: transText, language: voice)
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
        self.pickerView.dataSource = self as? UIPickerViewDataSource
        self.pickerView.delegate = self as? UIPickerViewDelegate
        
        if let user = username {
            let greeting = "\(String(describing: user)), What would you like to translate"
            self.speak(string: greeting, language: "en-US")
        }

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
                let bestString = result.bestTranscription.formattedString
                self.spokenTextLabel.text = bestString
                self.translate(text: bestString)
            } else if let error = error {
                print(error)

            }
        })
    }
    
    func translate(text:String?) -> String {
        if let toBeTranaslated = text {
            let newToBeTranslated = toBeTranaslated.replacingOccurrences(of: " ", with: "+")
            
            print(pickerView.selectedRow(inComponent: 0))
            if pickerView.selectedRow(inComponent: 0) == 0{
                language = "es"
                voice = "es-MX"
                pickerIdx = 0
            } else if pickerView.selectedRow(inComponent: 0) == 1 {
                language = "ko"
                voice = "ko-KR"
                pickerIdx = 1
            } else if pickerView.selectedRow(inComponent: 0) == 2 {
                language = "pt"
                voice = "pt-BR"
                pickerIdx = 2
            } else if pickerView.selectedRow(inComponent: 0) == 3 {
                language = "en"
                voice = "en-US"
                pickerIdx = 3
            }
            
            
            
            
            
            print(newToBeTranslated)
            let url = URL(string: "https://translation.googleapis.com/language/translate/v2?key=AIzaSyCxfmolIMWqxSLSJZXvBCkT1gmNKrbDRvQ&q=" + newToBeTranslated + "&target=" + language)
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
                        self.transText = translatedText
                        print(translatedText)
//                        self.translatedTextLabel.text = translatedText
                        DispatchQueue.main.async {
                            self.translatedTextLabel.text = translatedText
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
    
    func speak(string: String, language: String) {
        
        var voiceToUse: AVSpeechSynthesisVoice?
        for voice in AVSpeechSynthesisVoice.speechVoices() {
            if #available(iOS 9.0, *) {
                if voice.language == language {
                    voiceToUse = voice
                    print("Found Voice to use: \(voice)")
                    
                }
            }
        }
        
        let rawText = string
        let utterance = AVSpeechUtterance(string: rawText)
        utterance.voice = voiceToUse
        print(utterance.volume)
        self.synthesizer.speak(utterance)
        
    }
    
    func getRequestSession(urlStr: String, completionHandler:@escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        
        let url = URL(string: urlStr)
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: url!, completionHandler: completionHandler)
        
        task.resume()
    }
    
    
    func postPhraseRequestSession(urlStr: String, user_id: Int, newPhrase: String, newTrans: String, translated_lang: String, completionHandler:@escaping(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void)  {
        if let url = URL(string: urlStr){
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            let bodyData = "user=\(user_id)&phrase=\(newPhrase)&translation=\(newTrans)&translation_lang=\(translated_lang)"
            request.httpBody = bodyData.data(using: .utf8)
            let session = URLSession.shared
            let task = session.dataTask(with: request as URLRequest, completionHandler: completionHandler)
            task.resume()
        }
    }
    
    
    func postRequestSession(urlStr: String, username: String, completionHandler:@escaping(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void)  {
        if let url = URL(string: urlStr){
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            let bodyData = "username=\(username)"
            request.httpBody = bodyData.data(using: .utf8)
            let session = URLSession.shared
            let task = session.dataTask(with: request as URLRequest, completionHandler: completionHandler)
            task.resume()
        }
    }
    
}
