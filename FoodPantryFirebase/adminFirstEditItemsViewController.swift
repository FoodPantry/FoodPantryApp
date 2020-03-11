//  Copyright © 2020 Ashay Parikh, Rayaan Siddiqi. All rights reserved.


import UIKit
import FirebaseUI
import FirebaseStorage

class adminFirstEditItemsViewController: UIViewController,  UIPickerViewDelegate, UIPickerViewDataSource {
    
    //inventory page
    
    //colletion view
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchFoodBear: UISearchBar! //search bar
    
    //picker view for deciding sorting of the food items
    @IBOutlet var pickerField: UITextField!
    let yourPicker = UIPickerView()
    var pickerData: [String] = [String]()
    
    
    var foodItemsNameDataArray = [String]() //names of all the food items
    var storage: Storage! //storage

    var foodItemsImageArray = [UIImage]() //array of images of all the food items, loaded in the beginning
    var ref: DatabaseReference! //ref to db
    
    var searchedFoodItem = [String]() //array of food items that have been searched
    var searchedFoodItemImage = [String]() //same as above, but images
    var searchedFoodItemQuantity = [String]() //same as above, but max quantities
    
    var searching = false //if the user is searching for a food item
    
    //properties of the item cell
    var estimateWidth = 160.0
    var cellMarginSize = 16.0
    
    //all the food item names/titles
    var foodItems: [String] = []
    
    //all the data for the food items
    var data : [[String: Any]] =  []
    
    //sorted data
    var sortedData : [[String: Any]] =  []
    
    //selected food items after they have been searched for
    var selectedFoodItem: [String: Any]?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //This view will appear function notifies the view controller that its view is about to be added to a view hierarchy.
        //Hence that problem of the view not being reloaded is fixed, and the view is loaded everytime the tab bar clicks to a certain view
        ref = Database.database().reference()
        //initialize storage below
        storage = Storage.storage()
        
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.searchFoodBear.delegate = self
        
        
        //picker view
        
        yourPicker.delegate = self
        yourPicker.dataSource = self
        pickerField.inputView = yourPicker
        
        pickerData = ["All Items", "A-Z", "Z-A"] //sets the values for the picker view
        
        // Register cells
        self.collectionView.register(UINib(nibName: "ItemCell", bundle: nil), forCellWithReuseIdentifier: "ItemCell")
            
        // SetupGrid view
        self.setupGridView()
        
        
        var imageRecieved: Int = 0 //number of images recieved
        
        getDataFromFirebase(callback: {(success)-> Void in //gets data from the db
            if(success) { //success
                for i in 0..<self.data.count { //async loop
                    
                    let imageURL = self.data[i]["image"] as! String
                    
                    if(imageURL == "") {
                        self.data[i]["view"] = UIImage(named: "foodplaceholder.jpeg")
                        imageRecieved += 1
                        continue
                    }
                    
                    self.loadImageFromFirebase(url: imageURL, order: String(i), callback: {(img, order)-> Void in //loads an image from the firebase data
                               for i in 0..<self.data.count {
                                   if (self.data[i]["id"] as! String == order) { //compares the id of the image to the id of the current data
                                       self.data[i]["view"] = img //correct id, set the view key of the food item to the ui image
                                        imageRecieved += 1 //one more image recieved
                                   }
                               }
                               
                        if(imageRecieved == self.data.count) { //checks to see if all the images have been recieved
                            DispatchQueue.main.async { //reload page
                                self.dismiss(animated: false)
                                self.collectionView.reloadData()
                            }
                        }
                        
                               
                           })
                       }
            }
        })
        refresh()
    }
    
    
    @IBAction func dismissBack(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    
    func showLoadingAlert() { //shows a loading indicator on the screen
        let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)

        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
           super.didReceiveMemoryWarning()
           // Dispose of any resources that can be recreated.
       }
    
    
    // Number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    // The data to return fopr the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String {
        return pickerData[row]
    }
    
    //when the picker view is changed
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
       pickerField.text = pickerData[row]
    
        if(pickerData[row] == "A-Z") { //sorted a to z
            sortAtoZ()
        } else if(pickerData[row] == "Z-A") { //sorted z to a
            sortZtoA()
        }
        
    }
    
    //sorts the food items alphabetically using swifts sorting operators
    func sortAtoZ() {
        data = data.sorted { ($0["name"] as! String).lowercased() < ($1["name"] as! String).lowercased() }
        foodItems = foodItems.sorted { $0.lowercased() < $1.lowercased() }
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    func sortZtoA() {
           data = data.sorted { ($0["name"] as! String).lowercased() > ($1["name"] as! String).lowercased() }
           foodItems = foodItems.sorted { $0.lowercased() > $1.lowercased() }
           DispatchQueue.main.async {
               self.collectionView.reloadData()
           }
       }
    
    //gets data from firebase (found in other views)
    
    func getDataFromFirebase(callback: @escaping (_ success: Bool)->Void) {
        self.ref = Database.database().reference()
        let userID = Auth.auth().currentUser!.uid
                
        self.ref.child("Conant High School").child("Inventory").child("Food Items").observeSingleEvent(of: .value, with: { (snapshot) in
            
            var tempData : [[String: Any]] = []
            var tempNames: [String] = []
            var c: Int = 0
            for child in snapshot.children { //iterates through all the food items
                let snap = child as! DataSnapshot
                let key = snap.key
                let value: [String: Any] = snap.value as! [String : Any]
                //get the food item's data
                let name = value["Name"] as? String ?? ""
                let url = value["URL"] as? String ?? ""
                let checked = value["Checked Out"] as? String ?? ""
                let healthy = value["Healthy"] as? String ?? ""
                let quantity = value["Quantity"] as? String ?? ""
                let type = value["Type"] as? String ?? ""
                let info = value["Information"] as? String ?? ""
                let allergies = value["Allergies"] as? String ?? ""
                let id = String(c)
                
                //adds to array
                tempData.append(["name": name, "quantity": quantity, "amountCheckedOut": checked, "information": info, "healthy": healthy, "image": url, "type": type, "allergies": allergies, "id": id])
                tempNames.append(name)
                c += 1 //increments id count
            }
            
            //sets to instance field
            self.data = tempData
            self.foodItems = tempNames
            
            
             callback(true)
        })
    }
    
    //loads an image
    func loadImageFromFirebase(url: String, order: String, callback: @escaping (_ img: UIImage,_ order: String)->Void) { //loads an image based on the url, passed in an id and url
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: URL(string: url)!) {
                let image = UIImage(data: data)
                callback(image!, order) //returns a ui image
            }
        }
    }
    
    //page is refreshed
    @IBAction func refreshPage(_ sender: Any) {
        refresh()
        
    }
    
    func refresh() {
        var imageRecieved: Int = 0
        showLoadingAlert()
        getDataFromFirebase(callback: {(success)-> Void in //gets data from firebase
            if(success) { //same as the code in the viewDidLoad()
                                
                for i in 0..<self.data.count {
                    
                    let imageURL = self.data[i]["image"] as! String
                                       
                    if(imageURL == "") {
                        self.data[i]["view"] = UIImage(named: "foodplaceholder.jpeg")
                        imageRecieved += 1
                        continue
                    }
                    
                    self.loadImageFromFirebase(url: imageURL, order: String(i), callback: {(img, order)-> Void in
                               
                               for i in 0..<self.data.count {
                                   if (self.data[i]["id"] as! String == order) {
                                       self.data[i]["view"] = img
                                        imageRecieved += 1
                                   }
                               }
                               
                        if(imageRecieved == self.data.count) {
                            DispatchQueue.main.async {
                                self.dismiss(animated: false)
                                self.collectionView.reloadData()
                                self.pickerField.text = "All Items"
                            }
                        }
                        
                               
                           })
                       }
            }
        })
    }
    
    
    //item cell methods
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.setupGridView()
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }

    
    func setupGridView() {
        let flow = collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
        flow.minimumInteritemSpacing = CGFloat(self.cellMarginSize)
        flow.minimumLineSpacing = CGFloat(self.cellMarginSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //handle clicking of element

        if(searching) { //searching
            let index = indexPath[1] //gets the row value
            selectedFoodItem = sortedData[index] //since searchinng, the data for the item cells is mirrored in sorted data
        } else { //not searching for a food item
            let index = indexPath[1]
            selectedFoodItem = data[index] //data is based on the selected food item
        }
        
        
        self.performSegue(withIdentifier: "toItemPopover2", sender: self) //shows pop up view
    }
    
    @IBAction func unwindToFoodItemsSecond(_ unwindSegue: UIStoryboardSegue) {
        
    }
    
    //segue handler
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toItemPopover2"{
            let destinationVC = segue.destination as? adminEditPopUpViewController
            destinationVC?.name = (selectedFoodItem?["name"] as? String)!
            destinationVC?.quantity = (selectedFoodItem?["quantity"] as? String)!
            destinationVC?.checkedout = (selectedFoodItem?["amountCheckedOut"] as? String)!
            destinationVC?.information = (selectedFoodItem?["information"] as? String)!
            destinationVC?.healthy = (selectedFoodItem?["healthy"] as? String)!
            destinationVC?.image = (selectedFoodItem?["image"] as? String)!
            destinationVC?.type = (selectedFoodItem?["type"] as? String)!
            destinationVC?.allergies = (selectedFoodItem?["allergies"] as? String)!

        }
    }
    
    @IBAction func dismissBackToControls(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
}

extension adminFirstEditItemsViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if searching {
            return searchedFoodItem.count
        } else {

            return foodItems.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as! ItemCell

        if searching {
            cell.setData(text: searchedFoodItem[indexPath.row])
            var img: String = sortedData[indexPath.row]["image"] as! String
            if(sortedData[indexPath.row]["view"] != nil) {
                cell.itemImageView.image = sortedData[indexPath.row]["view"] as! UIImage
            }
            
        } else {
            cell.setData(text: foodItems[indexPath.row])
            let url: String = data[indexPath.row]["image"] as! String
            let id: String = data[indexPath.row]["id"] as! String
            
            if(data[indexPath.row]["view"] != nil) {
                cell.itemImageView.image = data[indexPath.row]["view"] as! UIImage
            }
            
                
            }
        return cell
    }
    
    
}


extension adminFirstEditItemsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.calculateWith()
        return CGSize(width: width, height: width)
    }
    
    func calculateWith() -> CGFloat {
        let estimatedWidth = CGFloat(estimateWidth)
        let cellCount = floor(CGFloat(self.view.frame.size.width / estimatedWidth))
        
        let margin = CGFloat(cellMarginSize * 1.75)
        let width = (self.view.frame.size.width - CGFloat(cellMarginSize) * (cellCount - 1) - margin) / cellCount
        
        return width
    }
}

extension adminFirstEditItemsViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        (searchedFoodItem, sortedData) = filterArray(items: foodItems, dataValues: data, searchText: searchText)
        searching = true
        collectionView.reloadData()
    }

    func filterArray(items: [String], dataValues: [[String: Any]], searchText: String) -> ([String], [[String: Any]]) {
        var newItems: [String] = []
        var newValues: [[String: Any]] = []
        
        var count = 0
        for item in items {
            if (item.contains(searchText)) {
                newItems.append(items[count])
                newValues.append(dataValues[count])
            }
            count += 1
        }
        return (newItems, newValues)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searching = false
        searchBar.text = ""
        collectionView.reloadData()
    }
    
    
    
}




