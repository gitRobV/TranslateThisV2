//
//  TranslationTableVC.swift
//  TranslateThisV2
//
//  Created by Robert on 7/27/17.
//  Copyright © 2017 R&R Developement. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation




class TranslationTableVC: UITableViewController {
    
    var phrases = [NSDictionary] ()
    let synthesizer = AVSpeechSynthesizer()
    let PhrasesAPI = "http://13.59.119.156/phrases/"
    
    func getRequestSession(urlStr: String, completionHandler:@escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        let url = URL(string: urlStr)
        let session = URLSession.shared
        let task = session.dataTask(with: url!, completionHandler: completionHandler)
        task.resume()
    }
    
    func speak(string: String) {
        let rawText = string
        let utterance = AVSpeechUtterance(string: rawText)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        self.synthesizer.speak(utterance)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getRequestSession(urlStr: PhrasesAPI, completionHandler: {
            data, response, error in
            do {
                if let requestResults = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSArray {
                    print(requestResults)
                    for object in requestResults {
                        let phrase = object as! NSDictionary
                        self.phrases.append(phrase)
                    }
                }
                DispatchQueue.main.async { self.tableView.reloadData() }
            } catch { print(error) }
        })
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return phrases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransCell", for: indexPath) as! TransCell
        let indexOffset = phrases.count - 1
        let newIndex = indexOffset - indexPath.row
        cell.PhraseLabel.text = phrases[newIndex]["phrase"] as? String
        cell.Delegate = self
        return cell
        
    }
    
    
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    
    
    
}




