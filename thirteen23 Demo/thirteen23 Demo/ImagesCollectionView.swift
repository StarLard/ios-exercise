//
//  ImagesCollectionView.swift
//  thirteen23 Demo
//
//  Created by Caleb Friden on 8/28/17.
//  Copyright © 2017 Caleb Friden. All rights reserved.
//

import UIKit

class ImagesCollectionView: UICollectionView {

    var interactiveIndexPath : IndexPath?
    var interactiveView : UIView?
    var interactiveCell : ImagesCollectionViewCell?
    var highlightedCells : [ImagesCollectionViewCell] = []
    var previousPoint : CGPoint?
    
    static let maximumDistanceDelta:CGFloat = 0.5
    
    override func beginInteractiveMovementForItem(at indexPath: IndexPath) -> Bool {
        
        self.interactiveIndexPath = indexPath
        
        self.interactiveCell = self.cellForItem(at: indexPath) as? ImagesCollectionViewCell
        
        self.interactiveView = UIImageView(image: self.interactiveCell?.snapshot())
        self.interactiveView?.frame = self.interactiveCell!.frame
        
        self.interactiveCell?.isHidden = true
        
        self.addSubview(self.interactiveView!)
        self.bringSubview(toFront: self.interactiveView!)
        
        return true
    }
    
    override func updateInteractiveMovementTargetPosition(_ targetPosition: CGPoint) {
        
        if let hoverIndexPath = self.indexPathForItem(at: targetPosition), hoverIndexPath != self.interactiveIndexPath {
            if let hoverCell = self.cellForItem(at: hoverIndexPath) as? ImagesCollectionViewCell, !highlightedCells.contains(hoverCell) {
                hoverCell.displaysShadow = true
                self.highlightedCells.append(hoverCell)
            }
        } else {
            for cell in self.highlightedCells {
                cell.displaysShadow = false
            }
            self.highlightedCells = []
        }
        
        self.interactiveView?.center = targetPosition
        self.previousPoint = targetPosition
    }
    
    override func endInteractiveMovement() {
        if let hoverIndexPath = self.indexPathForItem(at: previousPoint!), let interactiveIndexPath = self.interactiveIndexPath {
            let hoverCell = self.cellForItem(at: hoverIndexPath) as? ImagesCollectionViewCell
            if let interactiveImage = self.interactiveCell?.image {
                DemoService.sharedDemoService.setImagePosition(image: interactiveImage, position: Int16(hoverIndexPath.row))
            }
            if let hoverImage = hoverCell?.image {
                DemoService.sharedDemoService.setImagePosition(image: hoverImage, position: Int16(interactiveIndexPath.row))
            }
            self.performBatchUpdates({
                self.moveItem(at: interactiveIndexPath, to: hoverIndexPath)
                self.moveItem(at: hoverIndexPath, to: interactiveIndexPath)
            }, completion: {(finished) in
                self.cleanup()
            })
        } else {
            self.cleanup()
        }
    }
    
    override func cancelInteractiveMovement() {
        self.cleanup()
    }
    
    func cleanup() {
        self.interactiveCell?.isHidden = false
        self.interactiveView?.removeFromSuperview()
        self.interactiveView = nil
        self.interactiveCell = nil
        self.interactiveIndexPath = nil
        self.previousPoint = nil
        for cell in self.highlightedCells {
            cell.displaysShadow = false
        }
        self.highlightedCells = []
    }

}
