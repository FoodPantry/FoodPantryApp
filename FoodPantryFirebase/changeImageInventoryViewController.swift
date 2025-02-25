//
//  changeImageInventoryViewController.swift
//  FoodPantryFirebase
//
//  Created by Rayaan Siddiqi on 4/16/20.
//  Copyright © 2020 Rayaan Siddiqi. All rights reserved.
//

import UIKit
var newImageURLFromChanged = ""
class changeImageInventoryViewController: UIViewController {

        @IBOutlet weak var yesButton: UIButton!
        
        @IBOutlet weak var foodImageView: UIImageView!
        @IBOutlet weak var noButton: UIButton!
        var activeField: UITextField!
        
        @IBOutlet weak var backButton: UIButton!
        @IBOutlet weak var outOfHowMany: UILabel!
        var fullWordWithPlus = ""
        var imageSRCData: [String] = [String]()
        var indiciesOfSRC: [Int] = [Int]()
        var modifiedSRCData: [String] = [String]()
        var indexAtArray = 0;
        override func viewDidLoad() {
            super.viewDidLoad()

            yesButton.layer.cornerRadius = 15//15px
            yesButton.clipsToBounds = true
            
            yesButton.titleLabel?.minimumScaleFactor = 0.5
            yesButton.titleLabel?.numberOfLines = 1;
            yesButton.titleLabel?.adjustsFontSizeToFitWidth = true
            
            noButton.layer.cornerRadius = 15//15px
            noButton.clipsToBounds = true
            
            noButton.titleLabel?.minimumScaleFactor = 0.5
            noButton.titleLabel?.numberOfLines = 1;
            noButton.titleLabel?.adjustsFontSizeToFitWidth = true
            
            backButton.layer.cornerRadius = 15//15px
            backButton.clipsToBounds = true
            
            backButton.titleLabel?.minimumScaleFactor = 0.5
            backButton.titleLabel?.numberOfLines = 1;
            backButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
            print("food beloww")
            print(changeImageName)
    //        https://www.google.com/search?tbm=isch&as_q=vienna&tbs=isch
    //        https://www.google.com/search?tbm=isch&as_q=vienna&tbs=isz:lt,islt:4mp,sur:fmc
            
            let fullFoodNameArr = changeImageName.components(separatedBy: " ")
            
            fullWordWithPlus = changeImageName
            print(fullFoodNameArr)
            if(fullFoodNameArr.count>1){
                for x in 0..<fullFoodNameArr.count{
                    var currentWord = fullFoodNameArr[x]
                    print(currentWord)
                    if(x == 0){
                        fullWordWithPlus = currentWord + "+"
                    }
                    else if(x<fullFoodNameArr.count-1){
                        fullWordWithPlus += currentWord + "+"
                    }
                    else{
                        fullWordWithPlus += currentWord
                    }
                    
                }
            }
            
            print("full word below")
            print(fullWordWithPlus)
    //        https://www.google.com/search?tbm=isch&as_q=vienna+beach&tbs=isch&safari_group=9
    //        var fullURL = "https://www.google.com/search?tbm=isch&as_q=" + fullWordWithPlus + "&tbs=isch"
            
    //        var fullURL = "https://www.google.com/search?tbm=isch&as_q=" + fullWordWithPlus + "&tbs=isch"
            var fullURL = "https://www.bing.com/images/search?q=" + fullWordWithPlus + "&go=Search&qs=n&form=QBILPG&sp=-1&pq=apple+sauc&sc=8-10&sk=&cvid=3A1B11EC0FF740BABF32F0EBD132E7A2"
            //BING IMAGE SEARCH WORKS
            print("full url below")
            print(fullURL)
            let url = URL(string: fullURL)
            
    //        let url = URL(string: "https://www.google.com/search?tbm=isch&as_q=" + fullWordWithPlus + "&tbs=isch")
            
            let task = URLSession.shared.dataTask(with: url!) { (data, response , error) in
                
                if error != nil{
                    print(error)
                }
                else{
                    let htmlContent = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)//the HTML
                    if(htmlContent == nil){
                        let alert = UIAlertController(title: "This Feature is currently unavailable", message: "Please try again later!", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil);
                    }
                    else{
                         print(htmlContent)
                                        let stringOfHTMLContent: String = htmlContent as! String
                                        print("other one below")
                                        print(stringOfHTMLContent)
                                        print(stringOfHTMLContent.indices(of: "src="))
                                        self.indiciesOfSRC.append(contentsOf: stringOfHTMLContent.indices(of: "src="))
                                        print(self.indiciesOfSRC)//provides begining indicies
                                        
                        //                http://t1.gstatic.com/images?q=tbn:ANd9GcReGv2aOtZhU2V1Wf8GjWSkKdp7s3bGmHpl_iPVkeVXYXr2tHVJcVu98Tk
                                        
                                        print("printing other below")
                                        for x in 0..<self.indiciesOfSRC.count{
                        //                    print(stringOfHTMLContent.between(self.indiciesOfSRC[x], self.indiciesOfSRC[x] + 99))
                        //get first ss to last one
                        //                    var firstIndex = stringOfHTMLContent.substring(from: self.indiciesOfSRC[x]);
                        //                    print(firstIndex)
                                            
                                            print("other newest one")
                                            let currentRange = stringOfHTMLContent.substring(with: self.indiciesOfSRC[x]..<self.indiciesOfSRC[x] + 104)//do everything with this!
                                            print(currentRange)
                                            print(currentRange.substring(from: 5))
                                            self.imageSRCData.append(currentRange.substring(from: 5))//all the src gathered, now get https ones
                                            
                        //                    let range = text.substring(0..<3)
                        //                    print("")
                        //                    var lastIndexTo = stringOfHTMLContent.substring(from: self.indiciesOfSRC[x] + 99)
                        //                    print(lastIndexTo)
                        //                    print("")
                        //                    print(stringOfHTMLContent.between(firstIndex, lastIndexTo))
                                        }
                                        
                                        for y in 0..<self.imageSRCData.count{
                                            if(self.imageSRCData[y].contains("http")){
                                                print("contains http")
                                                self.modifiedSRCData.append(self.imageSRCData[y])//getting the actual images only with good link
                                            }
                                        }
                                        self.loadFirstImage();
                                        //next 99 characters
                                        
                                    }
                    }
                   
            
            }
            task.resume()
            outOfHowMany.text = "\(indexAtArray+1)/28"//loadds 28 @ a time
            

            
            
            // Do any additional setup after loading the view.
        }

        
        func loadFirstImage(){
            var currentlyAt = self.modifiedSRCData[self.indexAtArray] as! String
            var theURLOfFoodItem = currentlyAt.replacingOccurrences(of: "\"", with: "")
            self.foodImageView.load(url: URL(string: theURLOfFoodItem)!);
        }


        @IBAction func yesButtonTapped(_ sender: UIButton) {
            var imageURLSelected = self.modifiedSRCData[self.indexAtArray];
            newImageURLFromChanged = imageURLSelected;
            print(newImageURLFromChanged)
            dismiss(animated: true, completion: nil)
        }
        
        @IBAction func noButtonTapped(_ sender: UIButton) {
            if(indexAtArray != modifiedSRCData.count-1){
                indexAtArray += 1;
                print(self.modifiedSRCData[self.indexAtArray])
                var currentlyAt = self.modifiedSRCData[self.indexAtArray] as! String
                var temp1 = currentlyAt.replacingOccurrences(of: "\"", with: "")
                var theURLOfFoodItem = temp1.replacingOccurrences(of: ">", with: "")
                self.foodImageView.load(url: URL(string: theURLOfFoodItem)!);
                outOfHowMany.text = "\(indexAtArray+1)/\(self.modifiedSRCData.count)"
                backButton.isHidden = true;
                if(indexAtArray+1 == self.modifiedSRCData.count){
                    backButton.isHidden = false;
                }
            }
            else{
                print("choose other pic")
                backButton.isHidden = false;
            }
        }
        
        @IBAction func backButtonTapped(_ sender: UIButton) {
            if(indexAtArray-1 != -1){
                indexAtArray -= 1;
                print(self.modifiedSRCData[self.indexAtArray])
                var currentlyAt = self.modifiedSRCData[self.indexAtArray] as! String
                var temp1 = currentlyAt.replacingOccurrences(of: "\"", with: "")
                var theURLOfFoodItem = temp1.replacingOccurrences(of: ">", with: "")
                outOfHowMany.text = "\(indexAtArray+1)/\(self.modifiedSRCData.count)"
                self.foodImageView.load(url: URL(string: theURLOfFoodItem)!);
            }
            else{
                backButton.isHidden = true;
            }
        }
}
