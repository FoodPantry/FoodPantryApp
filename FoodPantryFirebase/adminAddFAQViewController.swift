//
//  adminAddFAQViewController.swift
//  FoodPantryFirebase
//
//  Created by Rayaan Siddiqi on 3/31/20.
//  Copyright © 2020 Rayaan Siddiqi. All rights reserved.
//

import UIKit
import FirebaseUI
class adminAddFAQViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var questionTextField: UITextField!
    @IBOutlet weak var answerTextField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet var infoLabel: UILabel!
    
    var ref: DatabaseReference!
    var PantryName = ""
    var activeField: UITextField!
    var numQuestionsFromFirebase: [Int] = [Int]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PantryName = UserDefaults.standard.object(forKey:"Pantry Name") as! String
        self.ref = Database.database().reference()
        
        addButton.layer.cornerRadius = 15//15px
        addButton.clipsToBounds = true
        
        addButton.titleLabel?.minimumScaleFactor = 0.5
        addButton.titleLabel?.numberOfLines = 1;
        addButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        
        infoLabel.layer.borderColor = UIColor.black.cgColor
        infoLabel.layer.borderWidth = 4.0
        infoLabel.layer.cornerRadius = infoLabel.frame.height / 8
        infoLabel.layer.backgroundColor = UIColor(displayP3Red: 247/255, green: 188/255, blue: 102/255, alpha: 1).cgColor
        

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //check if checking out is allowed
        ref.child(PantryName).child("FAQ Page").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            var tempData : [[String: Any]] = []
            var c: Int = 0
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                let key = snap.key
                let value: [String: Any] = snap.value as! [String : Any]
                
                let id = String(c)
                
                self.numQuestionsFromFirebase.append(Int(key)!)//adding each students atrributes to array
                c += 1
            }
            

        // ...
        }) { (error) in
            RequestError().showError()
            print(error.localizedDescription)
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
         NotificationCenter.default.addObserver(self, selector: #selector(adminAddFAQViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
         NotificationCenter.default.addObserver(self, selector: #selector(adminAddFAQViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
         
         questionTextField.delegate = self;
         answerTextField.delegate = self;
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
        
    func textFieldDidBeginEditing(_ textField: UITextField){
        self.activeField = textField
    }

    func textFieldDidEndEditing(_ textField: UITextField){
        activeField = nil
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            
            let first = (self.activeField?.frame.origin.y) ?? -1
            
            if(first != -1) {
                if (self.activeField?.frame.origin.y)! >= keyboardSize.height {
                    self.view.frame.origin.y = keyboardSize.height - (self.activeField?.frame.origin.y)!
                } else {
                    self.view.frame.origin.y = 0
                }
            }
            
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y = 0
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        
        checkNextIndex()
    }
    
    var timesAdded = 0;
    var nextNum = 0;
    func checkNextIndex(){
        guard let questionEntered = questionTextField.text else { return }
        guard let answerEntered = answerTextField.text else { return }
        timesAdded += 1;
        if(timesAdded == 1){
            var maxNumCurrently = numQuestionsFromFirebase.max()//!
            nextNum = maxNumCurrently! + 1;
        }
        else{
            nextNum += 1;
        }
                
        self.ref.child(self.PantryName).child("FAQ Page").child(String(nextNum)).child("Question").setValue(questionEntered)
        self.ref.child(self.PantryName).child("FAQ Page").child(String(nextNum)).child("Answer").setValue(answerEntered)
        
        let alert = UIAlertController(title: "FAQ Item Added!", message: "The Question & Answer which you entered has been added to the FAQ Page!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil);
    }
    

}
