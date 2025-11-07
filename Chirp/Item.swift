//
//  Item.swift
//  Chirp
//
//  Created by Connor Hammond on 11/6/25.
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
