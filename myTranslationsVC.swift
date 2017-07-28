//
//  myTranslationsVC.swift
//  TranslateThisV2
//
//  Created by Ruben Duran on 7/28/17.
//  Copyright © 2017 R&R Developement. All rights reserved.
//
import Foundation
import UIKit
import CoreData
import AVFoundation
class myTranslationsVC: UITableViewController {
    
    var username: String?
    
    var user_id: Int?
    
    var phaveList = [NSDictionary] ()
    
    let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var phrases = [NSDictionary] ()
    let synthesizer = AVSpeechSynthesizer()
    let PhrasesAPI = "http://13.59.119.156/phrases/"
    
    
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
        let indexOffset = phaveList.count - 1
        let newIndex = indexOffset - indexPath.row
        let phraseToSpeak = phaveList[newIndex]["translation"] as! String
        let language = phaveList[newIndex]["translation_lang"]
        
        speak(string: phraseToSpeak, languaged: language as! String)
        DispatchQueue.main.async { self.tableView.reloadData() }
        // speak(string: phraseToSpeak, languaged: "es-MX")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let userAPI = "http://13.59.119.156/users/"
        getRequestSession(urlStr: userAPI, completionHandler: {
            data, response, error in
            
            do {
                if let requestResults = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSArray {
                    print("Request Results: \(requestResults.count)")
                    for object in requestResults {
                        let currUsers = object as! NSDictionary
                        if currUsers["username"] as? String == self.username {
                            self.user_id = currUsers["id"] as? Int
                        }
                    }
                }
            } catch {
                print(error)
            }
            
        })
        
        getRequestSession(urlStr: PhrasesAPI, completionHandler: {
            data, response, error in
            do {
                if let requestResults = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSArray {
                    for object in requestResults {
                        let phrase = object as! NSDictionary
                        self.phrases.append(phrase)
                        if phrase["user"] as! Int == self.user_id {
                            self.phaveList.append(phrase)
                            self.tableView.reloadData()
                            print("test test")
                            print(self.phaveList)
                        }
                        
                    }
                }
                DispatchQueue.main.async { self.tableView.reloadData() }
            } catch { print(error) }
        })
        
        DispatchQueue.main.async { self.tableView.reloadData() }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
        
        
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return phaveList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransCell", for: indexPath) as! TransCell
        let indexOffset = phaveList.count - 1
        let newIndex = indexOffset - indexPath.row
        cell.PhraseLabel.text = phaveList[newIndex]["phrase"] as? String
        cell.indexPath = indexPath as NSIndexPath
        cell.Delegate2 = self
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        speakTranslation(for: indexPath as NSIndexPath)
        
    }
    
    
    //    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    //        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
    //        let item = self.phrases[indexPath.row]
    //
    //        self.managedObjectContext.delete(item)
    //
    //        do {
    //            try self.managedObjectContext.save()
    //        } catch {
    //            print("\(error)")
    //        }
    //        self.EventItemList.remove(at: indexPath.row)
    //        tableView.reloadData()
    //
    //        let edit = UITableViewRowAction(style: .normal, title: "Edit") { (action, indexPath) in
    //            self.performSegue(withIdentifier: "EventActionSegue", sender: indexPath)
    //        }
    //        edit.backgroundColor = UIColor.blue
    //        return [delete, edit]
    //    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    
}
