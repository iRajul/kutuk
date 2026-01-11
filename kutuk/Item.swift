//
//  Item.swift
//  kutuk
//
//  Created by Rajul Jain on 11/01/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
