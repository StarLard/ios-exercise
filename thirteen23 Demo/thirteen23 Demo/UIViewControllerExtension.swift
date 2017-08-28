//
//  UIViewControllerExtension.swift
//  thirteen23 Demo
//
//  Created by Caleb Friden on 8/27/17.
//  Copyright © 2017 Caleb Friden. All rights reserved.
//

import UIKit

extension UIViewController{
    
    func showActivityIndicator() {
        DispatchQueue.main.async {
            let spinner = UIActivityIndicatorView()
            let loadingView = UIView()
            
            loadingView.tag = 1
            loadingView.frame = self.view.frame
            loadingView.center = self.view.center
            loadingView.backgroundColor = UIColor.white
            loadingView.alpha = 0.3
            
            spinner.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
            spinner.color = UIColor.gray
            spinner.center = loadingView.center
            spinner.startAnimating()
            
            loadingView.addSubview(spinner)
            self.view.addSubview(loadingView)
        }
    }
    
    func hideActivityIndicator() {
        DispatchQueue.main.async {
            if let loadingView = self.view.viewWithTag(1) {
                for view in loadingView.subviews {
                    if let spinner = view as? UIActivityIndicatorView {
                        spinner.stopAnimating()
                        spinner.removeFromSuperview()
                    }
                }
                loadingView.removeFromSuperview()
            }
        }
    }
    
    func presentAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default,handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
