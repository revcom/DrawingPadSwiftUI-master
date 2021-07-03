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
    @Published var lineWidth: Double = 3.0

    func endOfShape(onSaved: @escaping (CKRecord.ID) -> Void) {
        currentDrawing.shapes.append(currentShape)
        saveShape(shape: currentShape) { id in onSaved(id) }
        currentShape = Shape(colour: color, width: lineWidth)
    }
    
    let cloud = CloudDrawing()

    func loadDrawing() -> Drawing? {
        return nil
    }
    
    func saveShape(shape: Shape, onSaved: @escaping (CKRecord.ID) -> Void ) {
        
        let newRecord = CKRecord(recordType: "Shape", recordID: CKRecord.ID(zoneID: .default))
        cloud.shapeToRecord(shape: shape, record: newRecord/*, reference: <#CKRecord.Reference#>*/)

        cloud.saveRecord(from: shape, record: newRecord, onSaved: { (savedRecordID) in
            self.currentShape.originalRecord = newRecord    //So it can be updated later if necessary
            onSaved(savedRecordID)
        })

//        let record = cloud.shapeToRecord(shape: currentShape, record: CKRecord(), reference: )
//        cloud.saveRecord(from: Drawing.self, record: <#T##CKRecord#>, onSaved: <#T##(CKRecord.ID) -> Void#>)
    }
}

class CloudDrawing: CloudBase {
    
//    private func drawingToRecord(drawing: Drawing, record: CKRecord, reference: CKRecord.Reference) {
//        shapeToRecord(shape: drawing.shapes.first!, record: <#T##CKRecord#>, reference: <#T##CKRecord.Reference#>)
//    }
    
    func shapeToRecord(shape: Shape, record: CKRecord /*, reference: CKRecord.Reference*/) {
//        record.setObject(reference, forKey: "Drawing")
        
        var points: [Double] = []
        for point in shape.points {
            points.append(Double(point.x))
            points.append(Double(point.y))
        }
        print ("Saving shape (\(shape.points.count) points)")
        record.setObject(points as __CKRecordObjCValue, forKey: "Points")
        record.setObject(shape.width as __CKRecordObjCValue, forKey: "Width")

        guard let colour = UIColor(shape.colour).rgb() else { return }
        record.setObject(colour as __CKRecordObjCValue, forKey: "Colour")
    }
}
