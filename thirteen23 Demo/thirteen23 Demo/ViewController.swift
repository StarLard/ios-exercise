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
        self.getDataFromAPI(jsonKey: "image_ids") { result, error in
            if let error = error {
                print(error)
                self.presentAlert(title: "Unable to download images", message: "Please try again")
                return
            }
            guard let result = result else {
                fatalError("Result from API was nil")
            }
            for id in result {
                self.getDataFromAPI(jsonKey: "url", apppendix: id) { result, error in
                    if let error = error {
                        print(error)
                        self.presentAlert(title: "Unable to download images", message: "Please try again")
                        return
                    }
                    guard let result = result else {
                        fatalError("Result from API was nil")
                    }
                    // Load images
                    print(result)
                }
            }
        }
    }
    
    // MARK: Properties (Private)
    private enum APIError: Error {
        case couldNotFetch(reason: String)
        case noResponse(reason: String)
        case conversionFailed(reason: String)
    }
    
    private func presentAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default,handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func getDataFromAPI(jsonKey: String, apppendix: String? = nil, completionHandler: @escaping ([String]?, Error?) -> Void) {
        var results: [String] = []
        var apiAddress = "https://t23-pics.herokuapp.com/pics"
        if let apppendix = apppendix {
            apiAddress = apiAddress  + "/\(apppendix)"
        }
        guard let apiURL = URL(string: apiAddress) else {
            fatalError("Unable to generate URL")
        }
        let urlRequest = URLRequest(url: apiURL)
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completionHandler(nil, APIError.couldNotFetch(reason: "Error fetching image data: \(error)"))
                return
            }
            guard let responseData = data else {
                completionHandler(nil, APIError.noResponse(reason: "Did not recieve data from API call"))
                return
            }
            do {
                guard let dataJSON = try JSONSerialization.jsonObject(with: responseData, options: [])
                    as? [String: Any] else {
                        completionHandler(nil, APIError.conversionFailed(reason: "Error trying to convert response data to JSON"))
                        return
                }
                if apppendix == nil {
                    guard let resultData = dataJSON[jsonKey] as? [String] else {
                        completionHandler(nil, APIError.conversionFailed(reason: "Could not get results from JSON"))
                        return
                    }
                    results = resultData
                }
                else {
                    guard let resultData = dataJSON[jsonKey] as? String else {
                        completionHandler(nil, APIError.conversionFailed(reason: "Could not get results from JSON"))
                        return
                    }
                    results.append(resultData)
                }
                completionHandler(results, nil)
                return
                
            } catch {
                completionHandler(nil, APIError.conversionFailed(reason: "Error trying to convert data to JSON"))
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
