//
//  MyTranslationsVC.swift
//  TranslateThisV2
//
//  Created by Ruben Duran on 7/28/17.
//  Copyright © 2017 R&R Developement. All rights reserved.
//
import Foundation
import UIKit
import CoreData
import AVFoundation

class MyTranslationsVC: UITableViewController {
    
    var username: String?
    var user_id: Int?
    var phrases = [NSDictionary] ()
    let synthesizer = AVSpeechSynthesizer()

    
    let PhrasesAPI = "http://13.59.227.74/phrases/"
    let userAPI = "http://13.59.227.74/users/"
    
    
    func getRequestSession(urlStr: String, completionHandler:@escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        let url = URL(string: urlStr)
        let session = URLSession.shared
        let task = session.dataTask(with: url!, completionHandler: completionHandler)
        task.resume()
    }
    
    func speak(string: String, languaged: String) {
        
        var voiceToUse: AVSpeechSynthesisVoice?
        for voice in AVSpeechSynthesisVoice.speechVoices() {
            if #available(iOS 9.0, *) {
                if voice.language == languaged {
                    voiceToUse = voice
                }
            }
        }
        
        let rawText = string
        let utterance = AVSpeechUtterance(string: rawText)
        utterance.voice = voiceToUse
        self.synthesizer.speak(utterance)
        
    }
    
    func speakTranslation(for indexPath: NSIndexPath) {
        let indexOffset = phrases.count - 1
        let newIndex = indexOffset - indexPath.row
        let phraseToSpeak = phrases[newIndex]["translation"] as! String
        let language = phrases[newIndex]["translation_lang"]
        
        speak(string: phraseToSpeak, languaged: language as! String)
        DispatchQueue.main.async { self.tableView.reloadData() }
        // speak(string: phraseToSpeak, languaged: "es-MX")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clearDict()
        
        if let user = username {
            getRequestSession(urlStr: userAPI, completionHandler: {
                data, response, error in
                print("Data: \(String(describing: data))")
                print("Response: \(String(describing: response))")
                print("Error: \(String(describing: error))")
                
                do {
                    if let requestResults = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSArray {
                        for object in requestResults {
                            let currUsers = object as! NSDictionary
                            if currUsers["username"] as? String == user {
                                if let newUser = currUsers["id"] {
                                    self.user_id = newUser as? Int
                                    print("the ONE")
                                    print("the user id is -- 1  -- \(String(describing: self.user_id!))")
                                }
//                                print(self.user_id)
//                                print("the user id ^^^^")
//                                print("the user id is -- 2  -- \(String(describing: self.user_id!))")
                            }
                            print("the ONE-two")
                        }
                    }
                    
                } //end of do
                catch{
                    print("no user")
                }
//                print("the user id is -- 3  -- \(String(describing: self.user_id!))")
                
                ///////////////
                self.getRequestSession(urlStr: self.PhrasesAPI, completionHandler: {
                    data, response, error in
                    do {
                        if let requestResults = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSArray {
                            for object in requestResults {
                                let phrase = object as! NSDictionary
                                print("the phrase ---")
                                print(phrase)
                                if phrase["user"] as? Int == self.user_id{
                                    self.phrases.append(phrase)
                                }
                                
                            }
                        }
                        DispatchQueue.main.async { self.tableView.reloadData() }
                    } catch { print(error) }
                })
                //////////////
                
            }) //end of completion handler
        }

        
        DispatchQueue.main.async { self.tableView.reloadData() }
    }
    

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return phrases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransCell", for: indexPath) as! TransCell
        let indexOffset = phrases.count - 1
        let newIndex = indexOffset - indexPath.row
        cell.PhraseLabel.text = phrases[newIndex]["phrase"] as? String
        cell.languageLabel.text = phrases[newIndex]["translation_lang"] as? String
        cell.indexPath = indexPath as NSIndexPath
        cell.Delegate2 = self
        return cell
        
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        speakTranslation(for: indexPath as NSIndexPath)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    private func clearDict(){
        phrases = []
    }
}
