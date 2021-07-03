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
    
    @Published var currentDrawing: Drawing = Drawing(name: "Default")
    @Published var currentShape: Shape = Shape(colour: Color.yellow, width: 2)
    @Published var drawings: [Drawing] = []
    @Published var color: Color = Color.yellow
    @Published var lineWidth: Double = 3.0
    
    init() {
        startNewDrawing()
    }

    func startNewDrawing() {
        drawings = []
        currentDrawing = Drawing(name: "Main")
        drawings.append(currentDrawing)
    }
    
    func endOfShape(onSaved: @escaping (CKRecord.ID) -> Void) {
        currentDrawing.shapes.append(currentShape)
        print ("Appended shape with \(currentShape.points.count) points")
//        saveShape(drawing: currentDrawing, shape: currentShape) { id in onSaved(id) }
        currentShape = Shape(colour: color, width: lineWidth)
        for (index, shape) in drawings.first!.shapes.enumerated() {
            print ("Shape \(index) points \(shape.points.count)")
        }
    }
    
    let cloud = CloudDrawing()

    func loadDrawing() -> Drawing? {
        return nil
    }
    
    func saveDrawing() {
        let drawingRecord = CKRecord(recordType: "Drawing", recordID: CKRecord.ID(zoneID: .default))
        
        guard var drawing = drawings.first else { print ("🔴 No drawings yet"); return }
        drawing.reference = CKRecord.Reference(record: drawingRecord, action: .deleteSelf)

        cloud.drawingToRecord(drawing: drawing, record: drawingRecord)
        cloud.saveRecord(from: drawing, record: drawingRecord, onSaved: { savedRecordID in
            drawing.originalRecord = drawingRecord
            self.saveShapesForDrawing(recordID: drawingRecord.recordID, shapes: drawing.shapes, onShapesSaved: {
                print ("Saved \(drawing.shapes.count) shapes")
            })
        })
    }
    
    func saveShape(drawing: Drawing, shape: Shape, onSaved: @escaping (CKRecord.ID) -> Void ) {
        
        let shapeRecord = CKRecord(recordType: "Shape", recordID: CKRecord.ID(zoneID: .default))
        guard let drawingReference = drawing.reference else { print ("🔴 Drawing has no reference yet"); return }
        cloud.shapeToRecord(shape: shape, record: shapeRecord, reference: drawingReference)

        cloud.saveRecord(from: shape, record: shapeRecord, onSaved: { savedRecordID in
            self.currentShape.originalRecord = shapeRecord    //So it can be updated later if necessary
            onSaved(savedRecordID)
        })
    }
    
    func saveShapesForDrawing(recordID: CKRecord.ID, shapes: [Shape], onShapesSaved: @escaping () -> Void) {
        let drawingReference = CKRecord.Reference(recordID: recordID, action: .deleteSelf)
        var shapeRecords: [CKRecord] = []
        
        for shape in shapes {
            let newRecord  = CKRecord(recordType: "Shape", recordID: CKRecord.ID(zoneID: .default))
            cloud.shapeToRecord(shape: shape, record: newRecord, reference: drawingReference)
            shapeRecords.append(newRecord)
            print ("Saving shape with \(shape.points.count) points")
        }
        
        cloud.saveRecords(from: shapes, records: shapeRecords, onSaved: { (savedRecordID) in
            onShapesSaved()
        })
    }
}

class CloudDrawing: CloudBase {
    
    func drawingToRecord(drawing: Drawing, record: CKRecord) {
        record.setObject(drawing.name as __CKRecordObjCValue, forKey: "Name")
    }
    
    func shapeToRecord(shape: Shape, record: CKRecord , reference: CKRecord.Reference) {
        record["Drawing"] = reference
        
        var points: [Double] = []
        for point in shape.points {
            points.append(Double(point.x))
            points.append(Double(point.y))
        }
        record.setObject(points as __CKRecordObjCValue, forKey: "Points")
        record.setObject(shape.width as __CKRecordObjCValue, forKey: "Width")

        guard let colour = UIColor(shape.colour).rgb() else { return }
        record.setObject(colour as __CKRecordObjCValue, forKey: "Colour")
    }
    
    
}
