//
//  DrawingControls.swift
//  DrawingPadSwiftUI
//
//  Created by Martin Mitrevski on 19.07.19.
//  Copyright © 2019 Mitrevski. All rights reserved.
//

import SwiftUI

struct DrawingControls: View {

    @ObservedObject var drawingVM: DrawingViewModel
    @State private var colorPickerShown = false
    
    @State var colour: Color = Color.red

    private let spacing: CGFloat = 40
    
    var body: some View {
        NavigationView {
            VStack {
                HStack(spacing: spacing) {
                    Button("Pick color") {
                        self.colorPickerShown = true
                    }
                    Button("Undo") {
                        if drawingVM.currentDrawing.shapes.count > 0 {
                            drawingVM.currentDrawing.shapes.removeLast()
                        }
                    }
                    Button("Clear") {
                        drawingVM.saveDrawing()
                        drawingVM.drawings = [Drawing]()
                    }
                }
                HStack {
                    Text("Pencil width")
                        .padding()
                    Slider(value: $drawingVM.currentShape.width, in: 1.0...15.0, step: 1.0)
                        .padding()
                }
            }

        }
        .frame(height: 200)
        .sheet(isPresented: $colorPickerShown, onDismiss: {
            self.colorPickerShown = false
        }, content: { () -> ColorPicker in
            ColorPicker(color: $drawingVM.currentShape.colour, colorPickerShown: self.$colorPickerShown)
        })
    }
}
