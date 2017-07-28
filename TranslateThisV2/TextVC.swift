//
//  TextVC.swift
//  TranslateThisV2
//
//  Created by Robert on 7/27/17.
//  Copyright © 2017 R&R Developement. All rights reserved.
//

import UIKit
import AVFoundation

class TextVC: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var username: String?
    var translatedText: String?
    
    let synthesizer = AVSpeechSynthesizer()
    var selectedVoice: String?
    
    
    
    
    
    @IBOutlet weak var phraseInput: UITextView!
    
    @IBOutlet weak var resultsLabel: UILabel!
    
    @IBOutlet weak var pickerView: UIPickerView!
    
    @IBAction func translateButtonPressed(_ sender: UIButton) {
        
        var process = String ()
        
        
        if let stringToParse = phraseInput.text {
            
            let parsedString = stringToParse.replacingOccurrences(of: " ", with: "+")
            var language = String ()
            var voice = String ()
            
            
            print(pickerView.selectedRow(inComponent: 0))
            if pickerView.selectedRow(inComponent: 0) == 0{
                language = "es"
                voice = "es-ES"
                process = "Traduciendo ahora"
            } else if pickerView.selectedRow(inComponent: 0) == 1 {
                language = "ko"
                voice = "ko-KR"
                process = "지금 번역 중입니다"
            } else if pickerView.selectedRow(inComponent: 0) == 2 {
                language = "pt"
                voice = "pt-BR"
                process = "Traduzindo agora"
            } else if pickerView.selectedRow(inComponent: 0) == 3 {
                language = "en"
                voice = "en-US"
                process = "Translating Now"
            }
            
            
            self.selectedVoice = voice
            
            let url = URL(string: "https://translation.googleapis.com/language/translate/v2?key=AIzaSyCxfmolIMWqxSLSJZXvBCkT1gmNKrbDRvQ&q=" + parsedString + "&target=" + language)
            
            
            
            let session = URLSession.shared
            let task = session.dataTask(with: url!, completionHandler: {
                
                data, response, error in
                do {
                    if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                        print(jsonResult)
                        let data = jsonResult["data"] as! NSDictionary
                        let transl = data["translations"] as! NSArray
                        let translationDict = transl[0] as! NSDictionary
                        self.translatedText = translationDict["translatedText"] as? String
                        
                        DispatchQueue.main.async {
                            self.resultsLabel.text = self.translatedText
                            self.newSpeak(string: process, languaged: voice)
                            self.newSpeak(string: self.translatedText!, languaged: voice)
                        }
                        
                    }
                    
                } catch {
                    print(error)
                }
            })
            task.resume()
        } else {
            print("Please write a valid word")
        }
        
    }
    
    
    
    
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        
        let newPhrase = phraseInput.text
        let newTrans = self.translatedText
        let user = username!
        
        var user_id: Int?
        var translated_lang: String?
        if let voice = self.selectedVoice {
            translated_lang = voice
            print(voice)
        }
        
        
        let userAPI = "http://13.59.119.156/users/"
        let phraseAPI = "http://13.59.119.156/phrases/"
        
        getRequestSession(urlStr: userAPI, completionHandler: {
            data, response, error in
            print("Data: \(String(describing: data))")
            print("Response: \(String(describing: response))")
            print("Error: \(String(describing: error))")
            do {
                if let requestResults = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSArray {
                    print("Request Results: \(requestResults.count)")
                    var userExists = false
                    if requestResults.count == 0 {
                        print("you are the First Ever User!!")
                    } else {
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
                                    self.postPhraseRequestSession(urlStr: phraseAPI, user_id: user_id!, newPhrase: newPhrase!, newTrans: newTrans!, translated_lang: translated_lang!, completionHandler: {
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
        
        
        self.phraseInput.text = nil
        self.resultsLabel.text = "Saved"
        
        
        
    }
    
    
    
    func getRequestSession(urlStr: String, completionHandler:@escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        
        let url = URL(string: urlStr)
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: url!, completionHandler: completionHandler)
        
        task.resume()
    }
    
    
//    func postPhraseRequestSession(urlStr: String, user_id: Int, newPhrase: String, newTrans: String,  completionHandler:@escaping(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void)  {
//        if let url = URL(string: urlStr){
//            var request = URLRequest(url: url)
//            request.httpMethod = "POST"
//            let bodyData = "user=\(user_id)&phrase=\(newPhrase)&translation=\(newTrans)"
//            request.httpBody = bodyData.data(using: .utf8)
//            let session = URLSession.shared
//            let task = session.dataTask(with: request as URLRequest, completionHandler: completionHandler)
//            task.resume()
//        }
//    }
    
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
    
    func speak(string: String) {
        let rawText = string
        let utterance = AVSpeechUtterance(string: rawText)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        self.synthesizer.speak(utterance)
        
    }
    
    func newSpeak(string: String, languaged: String) {
        
        var voiceToUse: AVSpeechSynthesisVoice?
        for voice in AVSpeechSynthesisVoice.speechVoices() {
            if #available(iOS 9.0, *) {
                if voice.language == languaged {
                    voiceToUse = voice
                    print("Found Voice to use: \(voice)")
                }
            }
        }
        
        let rawText = string
        let utterance = AVSpeechUtterance(string: rawText)
        utterance.voice = voiceToUse
        self.synthesizer.speak(utterance)
        
    }
    
    var languages = ["Spanish", "Korean", "Portuguese", "English"]
    
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideKeyboardWhenTappedAround()
        
        if let user = username {
            let greeting = "\(String(describing: user)), What would you like to translate"
            self.speak(string: greeting)
        }
        
        
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
        
    }
    
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return languages.count;
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return languages[row] as String
        
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
