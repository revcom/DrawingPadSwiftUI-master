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
    @Published var lineWidth: Double = 2
    
    var loadingInProgress = false
    var currentDrawingIndex = -1
    var currentDrawing: Drawing {
        get { return drawings[currentDrawingIndex] }
    }
    
    init() {
//        startNewDrawing()
    }
    
    func deleteDrawingAndShapes() {
        cloudDrawing.deleteRecord(recordID: currentDrawing.recordID) {
            self.startAndSaveNewDrawing()
            print ("Drawing and shapes deleted from iCloud")
        }
    }
    
    func clearDrawing() {
        if drawings.count > 0 {
            cloudDrawing.deleteDrawingAndShapes(drawing: currentDrawing) { [self] in
                drawings = []
                currentDrawingIndex = -1
                startNewDrawing()
                saveCurrentDrawing()
            }
        }
    }
    
    func removeLastShape() {
        let drawing = currentDrawing
        drawing.shapes.removeLast()
    }
    
    func startAndSaveNewDrawing() {
        startNewDrawing()
        saveCurrentDrawing()
    }

    func startNewDrawing() {
        drawings.append(Drawing(name: "Main"))
        currentDrawingIndex += 1
    }
    
    func endOfShape(onSaved: @escaping (CKRecord.ID) -> Void) {
        currentDrawing.shapes.append(currentShape)
        print ("Appended shape with \(currentShape.points.count) points. Drawing \(currentDrawing.name) has \(currentDrawing.shapes.count) shapes")
        saveShape(drawing: currentDrawing, shape: currentShape) { id in onSaved(id) }
        currentShape = Shape(colour: color, width: lineWidth)
        for (index, shape) in currentDrawing.shapes.enumerated() {
            print ("Shape \(index) points \(shape.points.count)")
        }
    }
    
    let cloudDrawing = CloudDrawing()
    let cloudShape = CloudShape()

    func loadDrawings(onFound: @escaping () -> Void) {
        loadingInProgress = true
        cloudDrawing.findAllDrawings(onFound: { drawings in
            DispatchQueue.main.async { [self] in
                if drawings.count > 0 {
                    self.drawings.append(contentsOf: drawings)
                    currentDrawingIndex = 0
                    cloudShape.findAllShapesFor(drawing: currentDrawing) { shapes in
                        currentDrawing.shapes.append(contentsOf: shapes)
                        print ("Drawings now...\(drawings.count) with \(currentDrawing.shapes.count) shapes")
                        objectWillChange.send()
                    } onError: { error in
                        print ("🔴 Error \(error.localizedDescription) loading shapes for drawing: \(currentDrawing.name)")
                    }
                    onFound()
                } else {
                    startAndSaveNewDrawing()
                    print ("No drawings found - start new drawing")
                }
                loadingInProgress = false
            }
        } , onError: { error in
            print ("🔴 Error \(error.localizedDescription) loading drawings")
        } )
    }
    
    func loadShape(recordID: CKRecord.ID) {
        cloudShape.fetchShapeBy(id: recordID) { shape in
            self.currentDrawing.shapes.append(shape)
            updates.recordsToUpdate.removeAll { $0 == recordID}
            print ("Shape added: \(self.currentDrawing.shapes.count) in total")
        }
    }
    
    func saveCurrentDrawing() {
        let drawingRecord = CKRecord(recordType: "Drawing", recordID: CKRecord.ID(zoneID: .default))

        cloudDrawing.drawingToRecord(drawing: currentDrawing, record: drawingRecord)
        cloudDrawing.saveRecord(from: currentDrawing, record: drawingRecord, onSaved: { [self] savedRecordID in
            currentDrawing.recordID = savedRecordID
            currentDrawing.originalRecord = drawingRecord
            saveShapesForDrawing(recordID: savedRecordID, shapes: self.currentDrawing.shapes, onShapesSaved: {
                print ("Saved \(self.currentDrawing.shapes.count) shapes")
            })
        })
    }
    
    func saveShape(drawing: Drawing, shape: Shape, onSaved: @escaping (CKRecord.ID) -> Void ) {
        
        cloudShape.initialiseSubscriptionsIfNecessary()

        let shapeRecord = CKRecord(recordType: "Shape", recordID: CKRecord.ID(zoneID: .default))
        guard let originalRecord = drawing.originalRecord  else { print ("🔴 Drawing has not been saved yet"); return }
        let drawingReference = CKRecord.Reference(record: originalRecord, action: .deleteSelf)
        cloudShape.shapeToRecord(shape: shape, record: shapeRecord, reference: drawingReference)

        cloudShape.saveRecord(from: shape, record: shapeRecord, onSaved: { savedRecordID in
            self.currentShape.originalRecord = shapeRecord    //So it can be updated later if necessary
            onSaved(savedRecordID)
        })
    }
    
    func saveShapesForDrawing(recordID: CKRecord.ID, shapes: [Shape], onShapesSaved: @escaping () -> Void) {
        cloudShape.initialiseSubscriptionsIfNecessary()


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
        newDrawing.recordID = record.recordID
        newDrawing.originalRecord = record

        print ("Found drawing named: \(newDrawing.name)")
        return newDrawing
    }
    
    func deleteDrawingAndShapes(drawing: Drawing, onDeleted: @escaping () -> Void) {
        guard let drawingRecord = drawing.originalRecord else { return }
        deleteRecord(recordID: drawingRecord.recordID) {
            print ("Drawing record and shapes successfully deleted")
            onDeleted()
        }
    }
    
}

class CloudShape: CloudBase {
    
    func initialiseSubscriptionsIfNecessary() {
        iCloudDatabase.fetchAllSubscriptions { subscriptions, error in
            if let error = error { print("🔴 Subscription error \(error.localizedDescription)"); return }
            guard let subscriptions = subscriptions else { print ("🔴 Nil subscriptions"); return }
            if subscriptions.count == 0 {
                self.startSubscription()
            }
        }
    }
    
    private func startSubscription() {
        let newSubscription = CKQuerySubscription(recordType: "Shape", predicate: NSPredicate(value: true),
          options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate])

        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true

        newSubscription.notificationInfo = notification
        
        iCloudDatabase.save(newSubscription) { (subscription, error) in
            if let error = error { print("🔴 Error starting subscription: \(error.localizedDescription)"); return }
            if let _ = subscription { print("Hurrah! We have a subscription") }
        }
    }
    
    func fetchShapeBy(id: CKRecord.ID, onFound: @escaping ((Shape) -> Void )) {
        fetchRecordByID(recordID: id) { shape in
            onFound(shape)
        }
    }
    
    func findAllShapesFor(drawing: Drawing, onFound: @escaping (([Shape]) -> Void), onError: @escaping (Error) -> Void ) {
        guard let originalRecord = drawing.originalRecord  else { print ("🔴 Drawing has not been saved yet"); return }
        let drawingReference = CKRecord.Reference(record: originalRecord, action: .deleteSelf)
        fetchRecordsByReference(reference: drawingReference, referenceTo: drawing, onFetched: { (shapes: [Shape]) in
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
