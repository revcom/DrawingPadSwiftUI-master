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
    
    @ObservedObject var updates: CloudUpdates

    @State var drawingsLoaded = false

    var body: some View {

        VStack(alignment: .center) {
            if drawingsLoaded {
                Text(drawingVM.currentDrawing.name + " Drawing").font(.largeTitle)
            } else {
                Text("Loading drawings...").font(.largeTitle)
            }
            DrawingPad(drawingVM: drawingVM)
                .onAppear(perform: { drawingVM.loadDrawings {
                    print ("Drawing loaded...")
                    drawingsLoaded = true
                } })

            DrawingControls(drawingVM: drawingVM)
        }
        .onReceive(updates.$didUpdate, perform: { _ in
            drawingVM.loadDrawings {
                print ("Drawing updated...")
            }
        })
    }
    
    func refreshDrawingView() -> some View {
        drawingVM.loadDrawings() {}
        return EmptyView()
    }
}
