//
//  ContentView.swift
//  DrawingPadSwiftUI
//
//  Created by Martin Mitrevski on 20.07.19.
//  Copyright © 2019 Mitrevski. All rights reserved.
//

import SwiftUI

let drawingVM = DrawingViewModel()

struct ContentView: View {
    
    var body: some View {
        VStack(alignment: .center) {
            Text("Draw here...").font(.largeTitle)

            DrawingPad(drawingVM: drawingVM)
//                .onAppear(perform: { drawingVM.loadDrawing() })
            DrawingControls(drawingVM: drawingVM)
        }
        .onAppear() {
            if drawingVM.drawings.count == 0 {
                drawingVM.currentDrawing.shapes.append(drawingVM.currentShape)
                drawingVM.drawings.append(drawingVM.currentDrawing)
            }
        }
    }
}
