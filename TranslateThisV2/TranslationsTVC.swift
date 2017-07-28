//
//  TranslationsTVC.swift
//  TranslateThisV2
//
//  Created by Robert on 7/27/17.
//  Copyright © 2017 R&R Developement. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import AVFoundation

class TranslationsTVC: UITableViewController {
    
    var phaveList = [PhaveItem] ()
    
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
        
        getRequestSession(urlStr: PhrasesAPI, completionHandler: {
            data, response, error in
            do {
                if let requestResults = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSArray {
                    for object in requestResults {
                        let phrase = object as! NSDictionary
                        self.phrases.append(phrase)
                        if phrase["user"] as! Int == 2 {
                            print(phrase["id"]!)
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
        
        
        
    }
    
    func fetchAllItems() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "PhaveItem")
        do {
            let result = try managedObjectContext.fetch(request)
            phaveList = result as! [PhaveItem]
        } catch {
            print("\(error)")
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return phrases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransCell", for: indexPath) as! TransCell
        let indexOffset = phrases.count - 1
        let newIndex = indexOffset - indexPath.row
        cell.PhraseLabel.text = phrases[newIndex]["phrase"] as? String
        cell.indexPath = indexPath as NSIndexPath
        cell.Delegate = self
        return cell
        
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
