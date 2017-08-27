//
//  ViewController.swift
//  thirteen23 Demo
//
//  Created by Caleb Friden on 8/26/17.
//  Copyright © 2017 Caleb Friden. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: Properties (IBOutlet)
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var trashCanLid: UIImageView!
    @IBOutlet weak var downloadButton: UIButton!

    // MARK: Properties (IBAction)
    @IBAction func downloadPressed(_ sender: Any) {
        self.loadImageIDs()
    }
    
    // MARK: Properties (Private)
    private func presentAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default,handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func loadImageIDs() {
        let idsAddress = "https://t23-pics.herokuapp.com/pics"
        guard let idsURL = URL(string: idsAddress) else {
            fatalError("Unable to generate URL")
        }
        let urlRequest = URLRequest(url: idsURL)
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) { data, response, error in
            // do stuff with response, data & error here
            if let error = error {
                print("Error fetching image IDs: \(error)")
                self.presentAlert(title: "Unable to download images", message: "Please try again")
                return
            }
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                self.presentAlert(title: "Unable to download images", message: "Please try again")
                return
            }
            do {
                guard let idsJSON = try JSONSerialization.jsonObject(with: responseData, options: [])
                    as? [String: Any] else {
                        print("Error trying to convert response data to JSON")
                        self.presentAlert(title: "Unable to download images", message: "Please try again")
                        return
                }
                
                // the todo object is a dictionary
                // so we just access the title using the "title" key
                // so check for a title and print it if we have one
                guard let imageIDs = idsJSON["image_ids"] as? [String] else {
                    print("Could not get ids list from JSON")
                    return
                }
                
                // now we have the todo
                // let's just print it to prove we can access it
                print(imageIDs)
            } catch  {
                print("Error trying to convert data to JSON")
                self.presentAlert(title: "Unable to download images", message: "Please try again")
                return
            }
        }
        task.resume()
    }

    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if !DemoService.sharedDemoService.imagesAreLoaded() {
            downloadButton.isHidden = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
