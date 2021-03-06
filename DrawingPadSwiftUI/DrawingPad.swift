//
//  DrawingPad.swift
//  DrawingPadSwiftUI
//
//  Created by Martin Mitrevski on 20.07.19.
//  Copyright © 2019 Mitrevski. All rights reserved.
//

import SwiftUI

struct DrawingPad: View {
    @ObservedObject var drawingVM: DrawingViewModel
    
    var body: some View {
        GeometryReader { geometry in
            if drawingVM.drawings.count > 0 {
                ZStack {
                    ForEach(drawingVM.currentDrawing.shapes, id: \.self) { shape in
                        //Draw previously constructed shapes
                        Path { path in
                            self.addShape(shape, toPath: &path)
                        }.stroke(shape.colour, lineWidth: CGFloat(shape.width))
                    }
                    //Draw the new shape curently under construction with the pen/finger
                    Path { path in
                        self.addShape(drawingVM.currentShape, toPath: &path)
                    }.stroke(drawingVM.currentShape.colour, lineWidth: CGFloat(drawingVM.currentShape.width))
                }
                .background(Color.black)
                .gesture(DragGesture(minimumDistance: 0.1)
                    .onChanged({ (value) in
                        let currentPoint = value.location
                        if currentPoint.y >= 0
                            && currentPoint.y < geometry.size.height {
                            drawingVM.currentShape.points.append(currentPoint)
                        }
                    })
                    .onEnded({ (value) in
                        drawingVM.endOfShape() { _ in print ("Ready for next stroke") }
                    })
                )
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private func addShape(_ shape: Shape, toPath path: inout Path) {
        let points = shape.points
        if points.count > 1 {
            for i in 0..<points.count-1 {
                let current = points[i]
                let next = points[i+1]
                path.move(to: current)
                path.addLine(to: next)
            }
        }
    }
    
}
