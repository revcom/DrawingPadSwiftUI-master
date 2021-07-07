//
//  ContentView.swift
//  DrawingPadSwiftUI
//
//  Created by Martin Mitrevski on 20.07.19.
//  Copyright © 2019 Mitrevski. All rights reserved.
//

import SwiftUI
import Combine
import CloudKit

let drawingVM = DrawingViewModel()

struct ContentView: View {
    
    @ObservedObject var updates: CloudUpdates

    @State var drawingsLoaded = false
    
    private var remoteBotificationPublisher: AnyPublisher<CGFloat, Never> {
            Publishers.Merge(
                NotificationCenter.default
                    .publisher(for: UIApplication.didReceiveRemoteNotification)
                    .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
                    .map { $0.height },
                NotificationCenter.default
                    .publisher(for: UIResponder.keyboardWillHideNotification)
                    .map { _ in CGFloat(0) }
            ).eraseToAnyPublisher()
        }

    var body: some View {

        VStack(alignment: .center) {
            if drawingsLoaded && drawingVM.drawings.count > 0 {
                Text(drawingVM.currentDrawing.name + " Drawing").font(.largeTitle)
            } else {
                Text("Loading drawings...").font(.largeTitle)
            }
            DrawingPad(drawingVM: drawingVM)
                .onAppear(perform: {
                    if !drawingVM.loadingInProgress {
                        drawingVM.loadDrawings {
                            print ("Drawing loaded...")
                            drawingsLoaded = true
                        }
                    }
                })

            DrawingControls(drawingVM: drawingVM)
        }
        .onReceive(updates.$didUpdate, perform: { _ in
            if updates.didUpdate {
                print ("onReceive")
                drawingVM.loadShape(recordID: updates.recordsToUpdate[0])
            }
        })
    }
}
