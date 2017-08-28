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
    var swapSet : Set<SwapDescription> = Set()
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
        
        self.interactiveView?.center = targetPosition
        self.previousPoint = targetPosition
    }
    
    override func endInteractiveMovement() {
        if (self.shouldSwap(previousPoint!)) {
            
            if let hoverIndexPath = self.indexPathForItem(at: previousPoint!), let interactiveIndexPath = self.interactiveIndexPath {
                
                let swapDescription = SwapDescription(firstItem: interactiveIndexPath.item, secondItem: hoverIndexPath.item)
                
                if (!self.swapSet.contains(swapDescription)) {
                    
                    self.swapSet.insert(swapDescription)
                    
                    self.performBatchUpdates({
                        self.moveItem(at: interactiveIndexPath, to: hoverIndexPath)
                        self.moveItem(at: hoverIndexPath, to: interactiveIndexPath)
                    }, completion: {(finished) in
                        self.swapSet.remove(swapDescription)
                        self.interactiveIndexPath = hoverIndexPath
                        self.cleanup()

                    })
                }
            } else {
                self.cleanup()
            }
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
        self.swapSet.removeAll()
    }
    
    func shouldSwap(_ newPoint: CGPoint) -> Bool {
        if let previousPoint = self.previousPoint {
            let distance = previousPoint.distanceToPoint(newPoint)
            return distance < ImagesCollectionView.maximumDistanceDelta
        }
        
        return false
    }

}

extension CGPoint {
    func distanceToPoint(_ p:CGPoint) -> CGFloat {
        return sqrt(pow((p.x - x), 2) + pow((p.y - y), 2))
    }
}

struct SwapDescription : Hashable {
    var firstItem : Int
    var secondItem : Int
    
    var hashValue: Int {
        get {
            return (firstItem * 10) + secondItem
        }
    }
}

func ==(lhs: SwapDescription, rhs: SwapDescription) -> Bool {
    return lhs.firstItem == rhs.firstItem && lhs.secondItem == rhs.secondItem
}
