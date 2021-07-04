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
            if drawingVM.drawings.count > 0 {
                Text(drawingVM.currentDrawing.name).font(.largeTitle)
            } else {
                Text("Loading drawings...").font(.largeTitle)
            }
            DrawingPad(drawingVM: drawingVM)
                .onAppear(perform: { drawingVM.loadDrawing {
                    print ("Drawing loaded...")
                } })
            DrawingControls(drawingVM: drawingVM)
        }
        .onAppear() {
//            if drawingVM.drawings.count == 0 {
//                drawingVM.currentDrawing.shapes.append(drawingVM.currentShape)
//                drawingVM.drawings.append(drawingVM.currentDrawing)
//            }
        }
    }
}
