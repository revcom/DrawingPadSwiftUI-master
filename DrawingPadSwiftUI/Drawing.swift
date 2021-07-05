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

class Drawing {
    var recordID: CKRecord.ID = CKRecord.ID()
    var originalRecord: CKRecord? = nil
    var reference: CKRecord.Reference? = nil
    var name: String = ""
    var shapes: [Shape] = []
    
    init (name: String) {
        self.name = name
    }
}

struct Shape {  //MUST remain struct (not class) otherwise shapes won't appear until mouseUp whe drawing
    var originalRecord: CKRecord?
    var points: [CGPoint]
    var colour: Color
    var width: Double
    
    init(colour: Color, width: Double, points: [CGPoint] = []) {
        originalRecord = nil
        self.points = points
        self.colour = colour
        self.width = width
    }
}
