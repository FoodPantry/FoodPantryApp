
//  Copyright © 2020 Ashay Parikh, Rayaan Siddiqi. All rights reserved.


import Foundation
import UIKit
import FirebaseUI
import FirebaseDatabase
import FirebaseAuth
import Firebase

var foodItemEnteringName = ""
class addMainViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    //all the a=labels
    @IBOutlet var nameLabel: UITextField!
    @IBOutlet var ingredientsLabel: UITextField!
    @IBOutlet var allergiesLabel: UITextField!
    @IBOutlet var typeLabel: UITextField!
    @IBOutlet var quantityLabel: UITextField!
    @IBOutlet var healthyLabel: UITextField!
    @IBOutlet var checkableLabel: UITextField!
    
    @IBOutlet var finishBtn: UIButton!
    @IBOutlet var cancelBtn: UIButton!
    @IBOutlet weak var chooseImgButton: UIButton!
    
    //options for the admin: adding more button
    @IBOutlet var addMoreBtn: UIButton!
    @IBOutlet var foodView: UIImageView!
    @IBOutlet var adminDirections: UILabel!
    
    var activeField: UITextField!

    var PantryName: String = ""

    
    var barcode = "" //food item barcode
    
    var food_title = "" //the actual food title
    var food_url = "" //url
    
    var errorMessage = "" //error message
    
    var manualEnter: Bool = false //true if the food item is manually loaded
    var manualTitle: String = "" //manual title that the user entered on the manualview (matches one of the titles in the database)
    
    var ref: DatabaseReference! //reference to the firebase database
    
    var existing: Bool = false //exists in the db
    
    var food_data: [String: Any] = [:] //data for the food item
    var found: Bool = false //if found the database, used for manual enter in previus view
    
    //for healthy or not healthy
    let yourPicker = UIPickerView()
    var pickerData: [String] = [String]()//data which can be selected via pickerView
    
    //for type
    let yourPicker2 = UIPickerView()
    var pickerData2: [String] = [String]()//data which can be selected via pickerView
    
    //for allergy
    let yourPicker3 = UIPickerView()
    var pickerData3: [String] = [String]()//data which can be selected via pickerView
    
    //the new food title
    
    var newFoodTitle = ""
    
    lazy var functions = Functions.functions()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        ref = Database.database().reference()
        self.PantryName = UserDefaults.standard.object(forKey:"Pantry Name") as! String

        nameLabel.isUserInteractionEnabled = false //cannot edit the food item name
        
        self.view.isUserInteractionEnabled = false
        
        
        print("below what found")
        print(foodItemEnteringName)
        addMoreBtn.layer.cornerRadius = 15
        addMoreBtn.clipsToBounds = true
        
        addMoreBtn.titleLabel?.minimumScaleFactor = 0.5
        addMoreBtn.titleLabel?.numberOfLines = 1;
        addMoreBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        
        chooseImgButton.layer.cornerRadius = 15
        chooseImgButton.clipsToBounds = true
        
        chooseImgButton.titleLabel?.minimumScaleFactor = 0.5
        chooseImgButton.titleLabel?.numberOfLines = 1;
        chooseImgButton.titleLabel?.adjustsFontSizeToFitWidth = true
           
        finishBtn.layer.cornerRadius = 15
        finishBtn.clipsToBounds = true
        
        finishBtn.titleLabel?.minimumScaleFactor = 0.5
        finishBtn.titleLabel?.numberOfLines = 1;
        finishBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        
        cancelBtn.layer.cornerRadius = 15
        cancelBtn.clipsToBounds = true
        
        cancelBtn.titleLabel?.minimumScaleFactor = 0.5
        cancelBtn.titleLabel?.numberOfLines = 1;
        cancelBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        
        //sets the keypad type
        
        quantityLabel.text = "1"
        quantityLabel.keyboardType = UIKeyboardType.numberPad
        //healthy picker
        
        yourPicker.delegate = self
        yourPicker.dataSource = self
        
        healthyLabel.inputView = yourPicker
        pickerData = ["Yes", "No"]
        
        yourPicker2.delegate = self
        yourPicker2.dataSource = self
        
        typeLabel.inputView = yourPicker2
        pickerData2 = ["Snack", "Breakfast", "Lunch", "Dinner", "Drink"]
        
        yourPicker3.delegate = self
        yourPicker3.dataSource = self
        
        allergiesLabel.inputView = yourPicker3
        pickerData3 = ["None", "Dairy", "Eggs", "Peanuts", "Tree Nuts", "Shellfish", "Wheat", "Soy", "Fish", "Other"]
        
        if (manualEnter) { //manually entered food item
            if(found) { //item exists in the db
                         
                //update screen
                self.existing = true
                self.food_title = food_data["name"] as! String
                self.nameLabel.text = (food_data["name"] as! String).trimTitle()
                self.ingredientsLabel.text = food_data["information"] as! String
                self.allergiesLabel.text = food_data["allergies"] as! String
                self.typeLabel.text = food_data["type"] as! String
                self.healthyLabel.text = food_data["healthy"] as! String
                self.checkableLabel.text = food_data["checkable"] as! String

                let url = food_data["image"] as! String
                self.food_url = url
                
                //load image
                if url != "" {
                    self.foodView.load(url: URL(string: url)!);
                } else {
                    self.foodView.image = UIImage(named: "foodplaceholder.jpeg")
                    print("reached here")
                    print(newImageURL)
                    chooseImgButton.isHidden = false;
                    if(newImageURL != ""){
                        self.foodView.load(url: URL(string: newImageURL)!);
                    }
                    else{
                        self.foodView.image = UIImage(named: "foodplaceholder.jpeg")
                        chooseImgButton.isHidden = false;
                    }
                   
                }
                
                self.adminDirections.text = "Existing Item\nEdit the Following"
                
                self.addItem(next: "addmore")
            } else {
                chooseImgButton.isHidden = false;
                self.existing = false
                nameLabel.isUserInteractionEnabled = true
                self.adminDirections.text = "New Item\nAdd the Following"
            }
            self.view.isUserInteractionEnabled = true

        } else { //used barcode
            getData { (title, error, image) in //gets the title (string) and error (boolean)
                DispatchQueue.main.async { //async thread
                    if(error) { //there is an error
                        self.errorMessage = title;
                         self.performSegue(withIdentifier: "addingError", sender: self) //go back to the qrcodeview screen
                    } else {
                        //check if it is in the database
                        
                        self.getFoodDataFromFirebase(callback: {(data, items)-> Void in //get data from the database
                            
                            
                            if(items.contains(title)) { //food item already exists
                                
                                print("found item")
                                
                                self.existing = true
                                let index: Int = items.firstIndex(of: title)! //gets index of the food item
                                
                                self.food_title = title
                                self.food_data = data[index]
                                //set to local variables
                                let ingredients: String = data[index]["information"] as! String
                                let url: String = data[index]["image"] as! String
                                let allergies = data[index]["allergies"] as! String
                                let type = data[index]["type"] as! String
                                let healthy = data[index]["healthy"] as! String
                                let checkable = data[index]["checkable"] as! String

                                //put on screen
                                self.nameLabel.text = title.trimTitle()
                                self.ingredientsLabel.text = ingredients
                                self.allergiesLabel.text = allergies
                                self.typeLabel.text = type
                                self.healthyLabel.text = healthy
                                self.checkableLabel.text = checkable

                                self.food_url = url
                                
                                if url != "" {
                                    self.foodView.load(url: URL(string: url)!);
                                } else {
                                    self.chooseImgButton.isHidden = false;
                                    self.foodView.image = UIImage(named: "foodplaceholder.jpeg")
                                    if(newImageURL != ""){
                                        self.foodView.load(url: URL(string: newImageURL)!);
                                        self.food_url = newImageURL
                                    }
                                    else{
                                        self.chooseImgButton.isHidden = false;
                                        self.foodView.image = UIImage(named: "foodplaceholder.jpeg")
                                    }
                                }
                                
                                self.adminDirections.text = "Existing Item\nEdit the Following"
                                
                                self.addItem(next: "addmore")
                                
                            } else { //new item
                                
                                print("new item")
                                
                                self.existing = false
                                if(newImageURL == ""){
                                    self.food_url = image
                                    print("this was reached")
                                }
                                else{
                                    self.food_url = newImageURL;
                                }
                                
                                self.food_title = title
                                
                                //admin sets the rest
                                self.nameLabel.text = title.trimTitle()

                                if image != "" {
                                    if(image.verifyUrl){
                                        self.foodView.load(url: URL(string: image)!);
                                    }
                                    else{
                                        self.chooseImgButton.isHidden = false;
                                    }
                                    
                                }
                                
                                self.adminDirections.text = "New Item\nAdd the Following"

                            }
                            self.view.isUserInteractionEnabled = true
                    })
                }
            }
        }
        }

                
    }
    
    
    @IBAction func nameLabelChanged(_ sender: Any) {
        
        self.food_title = self.nameLabel.text ?? ""
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.foodView.image = UIImage(named: "foodplaceholder.jpeg")
        if(newImageURL != ""){
            self.foodView.load(url: URL(string: newImageURL)!);
        }
        else{
            self.foodView.image = UIImage(named: "foodplaceholder.jpeg")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(addMainViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
               NotificationCenter.default.addObserver(self, selector: #selector(addMainViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        nameLabel.delegate = self;
        ingredientsLabel.delegate = self;
        allergiesLabel.delegate = self;
        typeLabel.delegate = self;
        quantityLabel.delegate = self;
        healthyLabel.delegate = self;
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
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if(pickerView == yourPicker) {
            return pickerData.count
        } else if(pickerView == yourPicker2) {
            return pickerData2.count
        }
        return pickerData3.count
    }
    
    // The data to return fopr the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String {
        if(pickerView == yourPicker) {
            return pickerData[row]
        } else if(pickerView == yourPicker2) {
            return pickerData2[row]
        }
        return pickerData3[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
      if(pickerView == yourPicker) {
            healthyLabel.text = pickerData[row]
      } else if(pickerView == yourPicker2) {
            typeLabel.text = pickerData2[row]
        } else {
            allergiesLabel.text = pickerData3[row]
        }
    }
    
    func getFoodDataFromFirebase(callback: @escaping (_ data: [[String: Any]], _ names: [String])->Void) { //returns a dict of all the food items in the database and their data, and a list of the names of the food items
        self.ref = Database.database().reference() //gets a reference
        
        //read the database
        self.ref.child(self.PantryName).child("Inventory").child("Food Items").observeSingleEvent(of: .value, with: { (snapshot) in
            
            //temp data and names
            var tempData : [[String: Any]] = [] //return 1
            var tempNames: [String] = [] //return 2
            var c: Int = 0 //assigns an id to each food item
            for child in snapshot.children { //each food item
                let snap = child as! DataSnapshot
                let key = snap.key //key
                let value: [String: Any] = snap.value as! [String : Any] //values
                
                //gets the values of each food item
                let name = value["Name"] as? String ?? ""
                let url = value["URL"] as? String ?? ""
                let checked = value["Checked Out"] as? String ?? ""
                let healthy = value["Healthy"] as? String ?? ""
                let quantity = value["Quantity"] as? String ?? ""
                let type = value["Type"] as? String ?? ""
                let info = value["Information"] as? String ?? ""
                let allergies = value["Allergies"] as? String ?? ""
                let checkable = value["Max Checked Out"] as? String ?? ""

                let id = String(c)
                
                //adds to the arrays
                tempData.append(["name": name, "quantity": quantity, "amountCheckedOut": checked, "information": info, "healthy": healthy, "image": url, "allergies": allergies, "type": type, "id": id, "key": key, "checkable": checkable])
                tempNames.append(name)
                c += 1 //increments id counter
            }
            
             callback(tempData, tempNames) //callback function
        }) { (error) in
            RequestError().showError()
            print(error.localizedDescription)
        }
    }

    
     func getData(_ completion: @escaping (String, Bool, String) -> ()) { //request method with the barcode API, returns the title and error
       //        let baseUrl = "https://api.upcitemdb.com/prod/trial/lookup?upc="
               let baseUrl = "https://api.barcodespider.com/v1/lookup?token=c35919b64b4aa4c38752&upc=" //url
               
               if barcode.count > 12 { //makes the barcode 12 characters long
                   let range = barcode.index(after: barcode.startIndex)..<barcode.endIndex
                   barcode = String(barcode[range])

               }
                
            let url = URL(string: baseUrl + barcode) //url with the barcode
               
               let task = URLSession.shared.dataTask(with: url!) { (data: Data?, response: URLResponse?, error: Error?) in //request
                   guard let data = data, error == nil else { return }

                   do {
                       let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any] ?? [:] //converts response to dict
                        //see https://devapi.barcodespider.com/documentation for api documentation
                    let foods = json["item_attributes"] as? [String: Any] ?? [:]//gets
                    let response = json["item_response"] as? [String: Any] ?? [:]
                       let status = response["status"] as? String ?? ""
                       if status != "OK" { //bad status
                        let message = response["message"] as? String ?? ""
                            completion(message, true, "none") //returns the message and error = true
                       } else { //good status, returns the title
                            let title = foods["title"] as! String ?? ""
                            let url = foods["image"] as! String ?? ""
                        
                            print(title)
                            print(url)
                        
                           completion(title, false, url)
                       }
                   } catch {
                       RequestError().showError()
                       return
                   }
                   
               }
               
               task.resume()
       }
    
        @IBAction func addMoreSelected(_ sender: Any) {
    
            addItem(next: "addmore")

        }
     
    @IBAction func finishSelected(_ sender: Any) { //same code as above
        
        addItem(next: "finish")
    }
    
    func addItem(next: String) {
        //update firebase
            
            let myGroup = DispatchGroup() //dispatch group, needed because the for loop is async

        
        if(existing) { //edit the current food item
                //update the current data in firebase
                
                myGroup.enter()
                self.view.isUserInteractionEnabled = false
                
                let key = food_data["key"] as! String //gets the uid of the food item

                
                self.ref.child(self.PantryName).child("Inventory").child("Food Items").child(key).observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    
                    //updating ingredients, allergies, type and quantity
                    
                    var newIngredients: String = self.ingredientsLabel.text!
                    var newAllergies: String = self.allergiesLabel.text!
                    var newType: String = self.typeLabel.text!
                    var additionalQuantity: String = self.quantityLabel.text!
                    var currentQuantity = self.food_data["quantity"] as! String
                    var newQuantity = Int(additionalQuantity)! + Int(currentQuantity)!
                    var newQuantity2 = String(newQuantity)
                    var newHealthy = self.healthyLabel.text!
                    var newCheckable = self.checkableLabel.text!

                    
                    //check for blanks
                    if(newIngredients == "" || newAllergies == "" || newType == "" || newHealthy == "" || newQuantity2 == "" || newCheckable == "") {
                        return
                    }
                    
                    //now update

                    self.ref.child(self.PantryName).child("Inventory").child("Food Items").child(key).child("Information").setValue(newIngredients.filterEmoji);
                    
                    self.ref.child(self.PantryName).child("Inventory").child("Food Items").child(key).child("Quantity").setValue(newQuantity2.filterEmoji);
                    
                    self.ref.child(self.PantryName).child("Inventory").child("Food Items").child(key).child("Type").setValue(newType.filterEmoji);
                    
                    self.ref.child(self.PantryName).child("Inventory").child("Food Items").child(key).child("Allergies").setValue(newAllergies.filterEmoji);
                    
                    self.ref.child(self.PantryName).child("Inventory").child("Food Items").child(key).child("Healthy").setValue(newHealthy.filterEmoji);
                    
                    self.ref.child(self.PantryName).child("Inventory").child("Food Items").child(key).child("Max Checked Out").setValue(newCheckable.filterEmoji);

                    //add the new barcode
                    
                    if(!self.manualEnter) {
                        self.ref.child(self.PantryName).child("Barcodes").child(self.barcode).setValue(key)
                    }
                    
                    myGroup.leave() //all done, can leave the group
                    self.view.isUserInteractionEnabled = true;
                  // ...
                  }) { (error) in
                    RequestError().showError()
                    print(error.localizedDescription)
                }
            } else { //need to add in a new food item
                //create new data
                
                var newTitle = food_title
                var newIngredients: String = self.ingredientsLabel.text!
                var newAllergies: String = self.allergiesLabel.text!
                var newType: String = self.typeLabel.text!
                var newQuantity: String = self.quantityLabel.text!
                var newCheckable: String = self.checkableLabel.text!
                var newURL = ""
                if(newImageURL != ""){
                    newURL = newImageURL
                }
                else{
                    newURL = food_url
                }
                
                var checkedOut = "0"
                var newHealthy = self.healthyLabel.text!
                
                //check for blanks
                if(newIngredients == "" || newAllergies == "" || newType == "" || newHealthy == "" || newQuantity == "" || newCheckable == "" || newTitle == "") {
                    return
                }
        
                
                let dic = NSMutableDictionary()
                dic.setValue(newTitle.filterEmoji, forKey: "Name")
                dic.setValue(newIngredients.filterEmoji, forKey: "Information")
                dic.setValue(newAllergies.filterEmoji, forKey: "Allergies")
                dic.setValue(newType.filterEmoji, forKey: "Type")
                dic.setValue(newQuantity.filterEmoji, forKey: "Quantity")
                dic.setValue(newURL.filterEmoji, forKey: "URL")
                dic.setValue(checkedOut.filterEmoji, forKey: "Checked Out")
                dic.setValue(newHealthy.filterEmoji, forKey: "Healthy")
                dic.setValue(newCheckable.filterEmoji, forKey: "Max Checked Out")

                myGroup.enter()
                self.view.isUserInteractionEnabled = false;
                
                let refChild = self.ref.child(self.PantryName).child("Inventory").child("Food Items").childByAutoId()
                
                if(!manualEnter) {
                    let uid = refChild.key!
                    self.ref.child(self.PantryName).child("Barcodes").child(self.barcode).setValue(uid)
                }
            
                refChild.updateChildValues(dic as [NSObject : AnyObject]) { (error, ref) in
                    if(error != nil){
                        RequestError().showError()
                        myGroup.leave() //all done, can leave the group
                        self.view.isUserInteractionEnabled = true;
                    } else{
                        print("\n\n\n\n\nAdded successfully...")
                        myGroup.leave() //all done, can leave the group
                        self.view.isUserInteractionEnabled = true;
                    }
                }
            
                //send notification to all users
            
                myGroup.enter()
                self.view.isUserInteractionEnabled = false;
            
            self.functions.httpsCallable("sendNewFoodMessage").call(["pantry": self.PantryName, "name": newTitle.filterEmoji]) { (result, error) in
                    if let error = error as NSError? {
                        if error.domain == FunctionsErrorDomain {
                            let code = FunctionsErrorCode(rawValue: error.code)
                            let message = error.localizedDescription
                            let details = error.userInfo[FunctionsErrorDetailsKey]
                            print(message)
                            print(code)
                            print(details)
                        }
                    }
                
                myGroup.leave()
                self.view.isUserInteractionEnabled = true;
              
              
                }
                
            }
        
            
            myGroup.notify(queue: .main) { //all loops finished, can do the call back
                
                if(next == "finish") {
                    self.view.isUserInteractionEnabled = true;
                    self.performSegue(withIdentifier: "BackToHome", sender: self)
                } else if(next == "addmore") {
                    self.performSegue(withIdentifier: "addMore", sender: self)

                }
                
            }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
          
           //continue with segue
           if segue.identifier == "addingError"{
               let destinationVC = segue.destination as? QRAddViewController
               destinationVC?.error = errorMessage
           } else if segue.identifier == "addMore"{
                let destinationVC = segue.destination as? QRAddViewController
                destinationVC?.message = "Food Item Added!"
            }
       }
    
    
}
