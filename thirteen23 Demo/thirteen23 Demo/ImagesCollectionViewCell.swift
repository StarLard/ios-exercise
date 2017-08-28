//
//  ImagesCollectionViewCell.swift
//  thirteen23 Demo
//
//  Created by Caleb Friden on 8/26/17.
//  Copyright © 2017 Caleb Friden. All rights reserved.
//

import UIKit

class ImagesCollectionViewCell: UICollectionViewCell {
    // MARK: Properties (IBOutlet)
    @IBOutlet weak var imageView: UIImageView!
    var image: Image?
    
    // MARK: Properties (Private)
    private var hasShadow: Bool = false
    
    // MARK: Properties (Public)
    func snapshot() -> UIImage {
        UIGraphicsBeginImageContext(self.bounds.size)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    var displaysShadow: Bool {
        get {
            return self.hasShadow
        }
        set {
            guard self.hasShadow != newValue else {
                return
            }
            if newValue && !self.hasShadow {
                self.layer.shadowRadius = 10
                self.layer.shadowOpacity = 0.5
                self.layer.shadowColor = UIColor.blue.cgColor
                self.layer.shadowOffset = CGSize(width: 0, height: 0)
                self.layer.masksToBounds = false
                self.clipsToBounds = false
            } else {
                self.layer.shadowOpacity = 0
            }
            self.hasShadow = newValue
        }
    }
    
}
