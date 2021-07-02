//
//  DrawingViewModel.swift
//  DrawingPadSwiftUI
//
//  Created by Robert Crago on 2/7/21.
//  Copyright © 2021 Mitrevski. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit
import CloudKit

class DrawingViewModel : ObservableObject {
    
    @Published var currentDrawing: Drawing = Drawing()
    @Published var currentShape: Shape = Shape(colour: Color.yellow, width: 2)
    @Published var drawings: [Drawing] = []
    @Published var color: Color = Color.yellow
    @Published var lineWidth: CGFloat = 3.0

    func endOfShape() {
        currentDrawing.shapes.append(currentShape)
        currentShape = Shape(colour: color, width: lineWidth)
    }
    
    let cloud = CloudDrawing()

    func loadDrawing() -> Drawing? {
        return nil
    }
    
    func saveDrawing(drawing: Drawing) {
//        cloud.saveRecord(from: Drawing.self, record: <#T##CKRecord#>, onSaved: <#T##(CKRecord.ID) -> Void#>)
    }
}

class CloudDrawing: CloudBase {
    
    private func drawingToRecord(drawing: Drawing, record: CKRecord, reference: CKRecord.Reference) {
//        shapeToRecord(shape: drawing.shapes.first!, record: <#T##CKRecord#>, reference: <#T##CKRecord.Reference#>)
    }
    
    func shapeToRecord(shape: Shape, record: CKRecord, reference: CKRecord.Reference) {
        record.setObject(reference, forKey: "Drawing")
        
        var points: [CGFloat] = []
        for point in shape.points {
            points.append(point.x)
            points.append(point.y)
        }
        record.setObject(points.map( Double.init ) as __CKRecordObjCValue, forKey: "Points")
        record.setObject(shape.width as __CKRecordObjCValue, forKey: "Width")

        guard let colour = UIColor(shape.colour).rgb() else { return }
        record.setObject(colour as __CKRecordObjCValue, forKey: "Colour")
    }
}
