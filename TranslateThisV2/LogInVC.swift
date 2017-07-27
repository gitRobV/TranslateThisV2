//
//  LogInVC.swift
//  TranslateThisV2
//
//  Created by Robert on 7/26/17.
//  Copyright © 2017 R&R Developement. All rights reserved.
//

import UIKit
import AVFoundation

class LogInVC: UIViewController {
        
        
        let synthesizer = AVSpeechSynthesizer()
        
    @IBOutlet weak var UserInput: UITextField!
    @IBOutlet weak var PasswordInput: UITextField!
    

    
    @IBAction func LogInPressed(_ sender: UIButton) {
        
        let username = UserInput.text
        
        if username == "" {
            UserInput.text = "Please enter a Valid Username"
        } else {
            performSegue(withIdentifier: "LoginSegue", sender: username)
        }
        
    }
        
        
    // Dismiss Keyboard
    // Should look for better way to handle the keyboard
    // v2.1
    
        func dismissKeyboard() {
            view.endEditing(true)
        }
    
        func hideKeyboardWhenTappedAround() {
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
            tap.cancelsTouchesInView = false
            view.addGestureRecognizer(tap)
        }
    
    
    // Speak Function
    // #MVC 
    // v2.1
    
    func speak(string: String) {
        let rawText = string
        let utterance = AVSpeechUtterance(string: rawText)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        self.synthesizer.speak(utterance)
        
    }
    
    
    // OVERRIDE FUNCTIONS
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            let revealController = segue.destination as! SWRevealViewController
            let destinationVC = revealController.frontViewController
        }
        
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.PasswordInput.isUserInteractionEnabled = false
            
            hideKeyboardWhenTappedAround()
            
            
            let greeting = "Greetings! Please provide a Username below."
            self.speak(string: greeting)
            
            
            // Do any additional setup after loading the view, typically from a nib.
        }
        
        override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Dispose of any resources that can be recreated.
        }
        
        
}

