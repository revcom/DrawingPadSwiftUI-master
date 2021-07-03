//
//  Drawing.swift
//  DrawingPadSwiftUI
//
//  Created by Martin Mitrevski on 19.07.19.
//  Copyright © 2019 Mitrevski. All rights reserved.
//

import CoreGraphics
import SwiftUI
import CloudKit

struct Drawing {
    var shapes: [Shape] = []
}

struct Shape {
    var originalRecord: CKRecord?
    var points: [CGPoint]
    var colour: Color
    var width: Double
    
    init(colour: Color, width: Double) {
        originalRecord = nil
        self.points = []
        self.colour = colour
        self.width = width
    }
}
