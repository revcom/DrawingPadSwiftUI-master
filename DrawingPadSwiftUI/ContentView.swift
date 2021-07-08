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
    
    @State private var remoteNotificationPublisher =
        NotificationCenter.default.publisher(for: UIApplication.didReceiveRemoteNotification)
        .compactMap { CKNotification(fromRemoteNotificationDictionary: $0.userInfo!) }
        .compactMap { $0 as! CKQueryNotification? }
        .map { $0.recordID! }.eraseToAnyPublisher()

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
        .onReceive(remoteNotificationPublisher) { id in print ("onReceive(d) notification...") }
//            if updates.didUpdate {
//                print ("onReceive")
//                drawingVM.loadShape(recordID: updates.recordsToUpdate[0])
//            }
//        })
    }
}
