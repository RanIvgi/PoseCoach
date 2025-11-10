//
//  Item.swift
//  PoseCoach
//
//  Created by Ran Ivgi on 05/11/2025.
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
