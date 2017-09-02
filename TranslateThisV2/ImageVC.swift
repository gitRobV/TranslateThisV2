//
//  ImageVC.swift
//  TranslateThisV2
//
//  Created by Ruben Duran on 8/20/17.
//  Copyright © 2017 R&R Developement. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation


class ImageVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    //Variables and Outlets
    @IBOutlet weak var importImageView: UIImageView!
    @IBOutlet weak var imageTextView: UITextView!
    @IBOutlet weak var pickerView: UIPickerView!
    
    var languages = ["Spanish", "Korean", "Portuguese", "English", "French", "German", "Italian", "Japanese", "Polish"]
    var language = "es"
    var voice = "es-MX"
    var imageText = ""
    var transText = ""
    var translatedText = ""
    var pickerIdx = 0
    var username: String?
    let synthesizer = AVSpeechSynthesizer()
    let myApiKey = "AIzaSyDLB5AS9JR78nUBcCIOxVaFuLCJnUjcNeA"
    let userAPI = "http://13.59.119.156/users/"
    let photoAPI = "http://13.59.119.156/photos/"

    
    //Buttons
    @IBAction func importImageBtn(_ sender: UIButton) {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        image.allowsEditing = false
        image.modalPresentationStyle = .popover
        self.present(image, animated: true) {
        }
    }
    
    @IBAction func takePictureBtn(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let image = UIImagePickerController()
            image.delegate = self
            image.allowsEditing = false
            image.sourceType = UIImagePickerControllerSourceType.camera
            image.cameraCaptureMode = .photo
            image.modalPresentationStyle = .fullScreen
            print("before")
            present(image, animated: true, completion: nil)
            print("after")
            image.popoverPresentationController?.sourceView = sender
            image.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sender.frame.size.width, height: sender.frame.size.height)
        } else {
            noCamera()
        }
    }
    
    
    
    
    @IBAction func translateBtn(_ sender: UIButton) {
//        var translatedText = translate(text: imageText)
        if translatedText == "" {
            imageTextView.text = "Please import or take a new photo, and select a language"
            self.speak(string: imageTextView.text, language: "en-US")
        } else {
            if pickerView.selectedRow(inComponent: 0) == pickerIdx {
                imageTextView.text = transText
                speak(string: transText, language: voice)
            } else{
                translatedText = translate(text: imageText)
                sleep(1)
//                imageTextView.text = translatedText
                self.speak(string: transText, language: voice)
            }

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
    
    //popover info
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
        popoverPresentationController?.delegate = self as? UIPopoverPresentationControllerDelegate
        if let user = username {
            let greeting = "\(String(describing: user)), What would you like to translate"
            self.speak(string: greeting, language: "en-US")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //Gen Functions
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            importImageView.contentMode = .scaleAspectFit
            importImageView.image = image
            let newImage = convertToGrayScale(image: image)
                
            print("the souce type \(picker.sourceType.rawValue)")
            
//            if picker.sourceType == UIImagePickerControllerSourceType.photoLibrary {
//                    
//                }
            var size = 100 as CGFloat
            if picker.sourceType.rawValue == 1 {
                size = 0.7 as CGFloat
            }
            let imageData:NSData = UIImageJPEGRepresentation(newImage, size)! as NSData
            
            let user = username!
            
            var user_id: Int?
            var translated_lang: String?
            translated_lang = voice
            
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
                            
                            self.postPhotoRequestSession(urlStr: self.photoAPI, user_id: user_id!, image:imageData, completionHandler: {
                                data, response, error in
                                print("user existed")
                                print("Data: \(String(describing: data!))")
                                print("Response: \(String(describing: response))")
                                print("Error -----: \(String(describing: error))")
                                do {
                                    
                                    if let requestResults = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                                        print("the request result \(requestResults)")
                                        DispatchQueue.main.async {
                                            self.imageTextView.text = requestResults["phrase"] as! String
                                        }
                                        self.imageText = requestResults["phrase"] as! String
                                        self.translatedText = self.translate(text: self.imageText)
                                    }
                                    else{print("the else else else")}
                                } catch { print("the catch \(error)")
                                    print("the data result \(String(describing: data))")
                                    }
                            })
                            
                        }
                        else {
                            self.postRequestSession(urlStr: self.userAPI, username: user, completionHandler: {
                                data, respones, error in
                                
                                do {
                                    if let userData = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                                        if let newUser = userData["id"] {
                                            user_id = newUser as? Int
                                            print("the user id \(String(describing: user_id))")
                                        }
                                        self.postPhotoRequestSession(urlStr: self.photoAPI, user_id: user_id!, image: imageData,  completionHandler: {
                                            data, response, error in
                                            print("new user")
                                            print("Data: \(String(describing: (data! as! NSMutableData) as NSData))")
                                            print("Response: \(String(describing: response))")
                                            print("Error: \(String(describing: error))")
                                            
                                            do {
                                                if let requestResults = try JSONSerialization.jsonObject(with: ((data! as! NSMutableData) as NSData) as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                                                    print("the request result \(requestResults)")
                                                    DispatchQueue.main.async {
                                                        self.imageTextView.text = requestResults["phrase"] as! String
                                                    }
                                                    self.imageText = requestResults["phrase"] as! String
                                                    self.translatedText = self.translate(text: self.imageText)
                            
                                                } else{
                                                    print("in the newuser else else")
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
            
        } else{
            print("Something went wrong")
        }
        self.dismiss(animated: true, completion: nil)
        print("out of here")
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
            } else if pickerView.selectedRow(inComponent: 0) == 4 {
                language = "fr"
                voice = "fr-FR"
                pickerIdx = 4
            } else if pickerView.selectedRow(inComponent: 0) == 5 {
                language = "de"
                voice = "de-DE"
                pickerIdx = 5
                
            } else if pickerView.selectedRow(inComponent: 0) == 6 {
                language = "it"
                voice = "it-IT"
                pickerIdx = 6
            } else if pickerView.selectedRow(inComponent: 0) == 7 {
                language = "ja"
                voice = "ja-JP"
                pickerIdx = 7
            } else if pickerView.selectedRow(inComponent: 0) == 8 {
                language = "pl"
                voice = "pl-PL"
                pickerIdx = 8
            }
            
            print(newToBeTranslated)
            
            let url = URL(string: "https://translation.googleapis.com/language/translate/v2?key=" + myApiKey + "&q="
                + newToBeTranslated + "&target=" + language)
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
                        DispatchQueue.main.async {
                            self.imageTextView.text = translatedText
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
        return imageTextView.text!
    }
    
    func noCamera(){
        let alertVC = UIAlertController(
            title: "No Camera",
            message: "Sorry, this device has no camera",
            preferredStyle: .alert)
        let okAction = UIAlertAction(
            title: "OK",
            style:.default,
            handler: nil)
        alertVC.addAction(okAction)
        present(
            alertVC,
            animated: true,
            completion: nil)
    }

    //imported funcs
    func getRequestSession(urlStr: String, completionHandler:@escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
    let url = URL(string: urlStr)
    let session = URLSession.shared
    let task = session.dataTask(with: url!, completionHandler: completionHandler)
    task.resume()
    }
    
    
    func postPhotoRequestSession(urlStr: String, user_id: Int, image: NSData, completionHandler:@escaping(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void)  {
        
        var urlRequest: NSMutableURLRequest? = nil
        if let url = URL(string: urlStr){
            urlRequest = URLRequest(url: url) as? NSMutableURLRequest
            urlRequest?.httpMethod = "POST"
            
            let uniqueId = ProcessInfo.processInfo.globallyUniqueString
            
            let postBody:NSMutableData = NSMutableData()
            var postData:String = String()
            let boundary:String = "------WebKitFormBoundary\(uniqueId)"
            
            urlRequest?.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField:"Content-Type")
            
            postData += "--\(boundary)\r\n"
            postData += "Content-Disposition: form-data; name=\"user\"\r\n\r\n"
            postData += "\(user_id)\r\n"

            postData += "--\(boundary)\r\n"
            postData += "Content-Disposition: form-data; name=\"image\"; filename=\"\(Int64(Date().timeIntervalSince1970*1000)).jpg\"\r\n"
            postData += "Content-Type: image/jpeg\r\n\r\n"
            postBody.append(postData.data(using: String.Encoding.utf8)!)
            postBody.append(image as Data)
            postData = String()
            postData += "\r\n"
            postData += "\r\n--\(boundary)--\r\n"
            postBody.append(postData.data(using: String.Encoding.utf8)!)
            
            urlRequest?.httpBody = NSData(data: postBody as Data) as Data

            let session = URLSession.shared
            let task = session.dataTask(with: urlRequest! as URLRequest, completionHandler: completionHandler)
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
    
    //speak func
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
    
    private func convertToGrayScale(image: UIImage) -> UIImage {
        let imageRect:CGRect = CGRect(x:0, y:0, width:image.size.width, height: image.size.height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let width = image.size.width
        let height = image.size.height
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        //have to draw before create image
        
        context?.draw(image.cgImage!, in: imageRect)
        let imageRef = context!.makeImage()
        let newImage = UIImage(cgImage: imageRef!)
        
        return newImage
    }
    
}

