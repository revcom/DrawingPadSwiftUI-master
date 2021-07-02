//
//  Drawing.swift
//  DrawingPadSwiftUI
//
//  Created by Martin Mitrevski on 19.07.19.
//  Copyright © 2019 Mitrevski. All rights reserved.
//

import CoreGraphics
import SwiftUI

struct Drawing {
    var shapes: [Shape]
}

struct Shape {
    var points: [CGPoint]
    var colour: Color
    var width: CGFloat
}
