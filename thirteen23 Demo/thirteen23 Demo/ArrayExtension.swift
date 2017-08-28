//
//  ArrayExtension.swift
//  thirteen23 Demo
//
//  Created by Caleb Friden on 8/27/17.
//  Copyright © 2017 Caleb Friden. All rights reserved.
//

import Foundation

extension Array {
    mutating func changeElementIndex(from: Int, to: Int) {
        insert(remove(at: from), at: to)
    }
}
