//
//  WebService.swift
//  thirteen23 Demo
//
//  Created by Caleb Friden on 8/27/17.
//  Copyright © 2017 Caleb Friden. All rights reserved.
//

import UIKit

class WebService {
    
    // MARK: Properties (Private)
    private enum DemoError: Error {
        case couldNotFetch(reason: String)
        case noResponse(reason: String)
        case conversionFailed(reason: String)
    }
    
    // MARK: Properties (Public)
    func getDataFromAPI(jsonKey: String,
                                apppendix: String? = nil,
                                completionHandler: @escaping (_ results: [String]?, _ error: Error?) -> Void) {
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
                completionHandler(nil, DemoError.couldNotFetch(reason: "Error fetching data: \(error)"))
                return
            }
            guard let responseData = data else {
                completionHandler(nil, DemoError.noResponse(reason: "Did not recieve data from API call"))
                return
            }
            do {
                guard let dataJSON = try JSONSerialization.jsonObject(with: responseData, options: [])
                    as? [String: Any] else {
                        completionHandler(nil, DemoError.conversionFailed(reason: "Error trying to convert response data to JSON"))
                        return
                }
                if apppendix == nil {
                    guard let resultData = dataJSON[jsonKey] as? [String] else {
                        completionHandler(nil, DemoError.conversionFailed(reason: "Could not get results from JSON"))
                        return
                    }
                    results = resultData
                }
                else {
                    guard let resultData = dataJSON[jsonKey] as? String else {
                        completionHandler(nil, DemoError.conversionFailed(reason: "Could not get results from JSON"))
                        return
                    }
                    results.append(resultData)
                }
                completionHandler(results, nil)
                return
                
            } catch {
                completionHandler(nil, DemoError.conversionFailed(reason: "Error trying to convert data to JSON"))
                return
            }
        }
        task.resume()
    }
    
    func downloadImageFromUrl(url: URL, completionHandler: @escaping (_ image: UIImage?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                completionHandler(nil, DemoError.couldNotFetch(reason: "Error fetching image data: \(error)"))
                return
            }
            guard let responseData = data else {
                completionHandler(nil, DemoError.noResponse(reason: "Did not recieve image data from server"))
                return
            }
            print("Download for \(response?.suggestedFilename ?? url.lastPathComponent) finished")
            DispatchQueue.main.async() { () -> Void in
                guard let image = UIImage(data: responseData) else {
                    completionHandler(nil, DemoError.conversionFailed(reason: "Could not convert response data to image"))
                    return
                }
                completionHandler(image, nil)
            }
        }.resume()
    }
    
    // MARK: Properties (Static)
    static let sharedWebService = WebService()
}
