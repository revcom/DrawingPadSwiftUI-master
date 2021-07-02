//
//  DrawingViewModel.swift
//  DrawingPadSwiftUI
//
//  Created by Robert Crago on 2/7/21.
//  Copyright © 2021 Mitrevski. All rights reserved.
//

import Foundation
import CloudKit

class DrawingViewModel : ObservableObject {
    
    let cloud = CloudDrawing()

    func loadDrawing() -> Drawing? {
        return nil
    }
    
    func saveDrawing(drawing: Drawing) {
        cloud.saveRecord(from: Drawing.self, record: <#T##CKRecord#>, onSaved: <#T##(CKRecord.ID) -> Void#>)
    }
}

class CloudDrawing: CloudBase {
    
    private func drawingToRecord(drawing: Drawing, record: CKRecord, reference: CKRecord.Reference) {
        record.setObject(reference, forKey: "Shapes")
    }
    
    private func shapeToRecord(shape: Drawing, record: CKRecord, reference: CKRecord.Reference) {
        record.setObject(reference, forKey: "Drawing")
        record.setObject(shape.points as __CKRecordObjCValue, forKey: "Points")
        record.setObject(shape.colour as __CKRecordObjCValue, forKey: "Colour")
        record.setObject(shape.width as __CKRecordObjCValue, forKey: "Width")
    }
}
