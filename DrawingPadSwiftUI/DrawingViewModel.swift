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
    
    @Published var currentShape: Shape = Shape(colour: Color.yellow, width: 2)
    @Published var drawings: [Drawing] = []
    @Published var color: Color = Color.yellow
    @Published var lineWidth: Double = 3.0
    
    var currentDrawingIndex = -1
    var currentDrawing: Drawing {
        get { return drawings[currentDrawingIndex] }
    }
    
    init() {
//        startNewDrawing()
    }
    
    func removeLastShape() {
        let drawing = currentDrawing
        drawing.shapes.removeLast()
    }

    func startNewDrawing() {
        drawings.append(Drawing(name: "Main"))
        currentDrawingIndex += 1
    }
    
    func endOfShape(onSaved: @escaping (CKRecord.ID) -> Void) {
        currentDrawing.shapes.append(currentShape)
        print ("Appended shape with \(currentShape.points.count) points. Drawing \(currentDrawing.name) has \(currentDrawing.shapes.count) shapes")
//        saveShape(drawing: currentDrawing, shape: currentShape) { id in onSaved(id) }
        currentShape = Shape(colour: color, width: lineWidth)
        for (index, shape) in currentDrawing.shapes.enumerated() {
            print ("Shape \(index) points \(shape.points.count)")
        }
    }
    
    let cloudDrawing = CloudDrawing()
    let cloudShape = CloudShape()

    func loadDrawings(onFound: @escaping () -> Void) {
        
        cloudDrawing.findAllDrawings(onFound: { drawings in
            DispatchQueue.main.async { [self] in
                if drawings.count > 0 {
                    self.drawings.append(contentsOf: drawings)
                    currentDrawingIndex = 0
                    cloudShape.findAllShapesFor(drawing: currentDrawing) { shapes in
                        currentDrawing.shapes.append(contentsOf: shapes)
                        print ("Drawings now...\(drawings.count)")
                        objectWillChange.send()
                    } onError: { error in
                        print ("🔴 Error \(error.localizedDescription) loading shapes for drawing: \(currentDrawing.name)")
                    }
                    onFound()
                } else {
                    startNewDrawing()
                }
            }
        } , onError: { error in
            print ("🔴 Error \(error.localizedDescription) loading drawings")
        } )
    }
    
    func saveDrawing() {
        let drawingRecord = CKRecord(recordType: "Drawing", recordID: CKRecord.ID(zoneID: .default))
        
        currentDrawing.reference = CKRecord.Reference(record: drawingRecord, action: .deleteSelf)

        cloudDrawing.drawingToRecord(drawing: currentDrawing, record: drawingRecord)
        cloudDrawing.saveRecord(from: currentDrawing, record: drawingRecord, onSaved: { savedRecordID in
            self.currentDrawing.originalRecord = drawingRecord
            self.saveShapesForDrawing(recordID: drawingRecord.recordID, shapes: self.currentDrawing.shapes, onShapesSaved: {
                print ("Saved \(self.currentDrawing.shapes.count) shapes")
            })
        })
    }
    
    func saveShape(drawing: Drawing, shape: Shape, onSaved: @escaping (CKRecord.ID) -> Void ) {
        
        let shapeRecord = CKRecord(recordType: "Shape", recordID: CKRecord.ID(zoneID: .default))
        guard let drawingReference = drawing.reference else { print ("🔴 Drawing has no reference yet"); return }
        cloudShape.shapeToRecord(shape: shape, record: shapeRecord, reference: drawingReference)

        cloudShape.saveRecord(from: shape, record: shapeRecord, onSaved: { savedRecordID in
            self.currentShape.originalRecord = shapeRecord    //So it can be updated later if necessary
            onSaved(savedRecordID)
        })
    }
    
    func saveShapesForDrawing(recordID: CKRecord.ID, shapes: [Shape], onShapesSaved: @escaping () -> Void) {
        let drawingReference = CKRecord.Reference(recordID: recordID, action: .deleteSelf)
        var shapeRecords: [CKRecord] = []
        
        for shape in shapes {
            let newRecord  = CKRecord(recordType: "Shape", recordID: CKRecord.ID(zoneID: .default))
            cloudShape.shapeToRecord(shape: shape, record: newRecord, reference: drawingReference)
            shapeRecords.append(newRecord)
            print ("Saving shape with \(shape.points.count) points")
        }
        
        cloudShape.saveRecords(from: shapes, records: shapeRecords, onSaved: { (savedRecordID) in
            onShapesSaved()
        })
    }
}

class CloudDrawing: CloudBase {
    
    func findAllDrawings(onFound: @escaping (([Drawing]) -> Void ), onError: @escaping (Error) -> Void ) {
        findAllRecords(onFound: onFound, onError: onError)
    }
    
    func drawingToRecord(drawing: Drawing, record: CKRecord) {
        record.setObject(drawing.name as __CKRecordObjCValue, forKey: "Name")
    }

    override func recordToResult(record: CKRecord) -> Any? {
        let drawingName = record["Name"] as! String
        let newDrawing = Drawing(name: drawingName)
        newDrawing.originalRecord = record
        newDrawing.reference = CKRecord.Reference(recordID: record.recordID, action: .none)

        print ("Found drawing named: \(newDrawing.name)")
        return newDrawing
    }
    
}

class CloudShape: CloudBase {
    
    func findAllShapesFor(drawing: Drawing, onFound: @escaping (([Shape]) -> Void), onError: @escaping (Error) -> Void ) {
        fetchRecordsByReference(reference: drawing.reference!, referenceTo: drawing, onFetched: { (shapes: [Shape]) in
            print ("Found \(shapes.count) shapes")
            onFound(shapes)
        })
    }
    
    override func recordToResult(record: CKRecord) -> Any? {
        let colourRGB = record["Colour"] as! Int
        let shapeColour = Color(UIColor(rgb: colourRGB))
        let shapeWidth = record["Width"] as! Double
        
        let xPoints = record["XPoints"] as! [Double]
        let yPoints = record["YPoints"] as! [Double]
        var points:[CGPoint] = []

        for index in 0..<xPoints.count {
            points.append(CGPoint(x: xPoints[index], y: yPoints[index]))
        }
        print ("Restored shape with: \(points.count) points")
        return Shape(colour: shapeColour, width: shapeWidth, points: points)
    }

    func shapeToRecord(shape: Shape, record: CKRecord , reference: CKRecord.Reference) {
        record["Drawing"] = reference
        
        var XPoints: [Double] = []
        var YPoints: [Double] = []
        for point in shape.points {
            XPoints.append(Double(point.x))
            YPoints.append(Double(point.y))
        }
        record.setObject(XPoints as __CKRecordObjCValue, forKey: "XPoints")
        record.setObject(YPoints as __CKRecordObjCValue, forKey: "YPoints")
        record.setObject(shape.width as __CKRecordObjCValue, forKey: "Width")

        guard let colour = UIColor(shape.colour).rgb() else { return }
        record.setObject(colour as __CKRecordObjCValue, forKey: "Colour")
    }
}
