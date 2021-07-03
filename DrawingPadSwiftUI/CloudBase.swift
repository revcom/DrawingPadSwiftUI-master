//
//  CloudBase.swift
//  DrawingPadSwiftUI
//
//  Created by Robert Crago on 13/4/21.
//

import Foundation
import CloudKit

class CloudBase {
    
    enum Status { case timeoutError, otherError, completed }
    
    let iCloudDatabase = CKContainer(identifier: "iCloud.com.revcomputing.SharedDrawing").privateCloudDatabase
//    static let ourZone = "WhereWhenHowMuch"
    
    //MARK: - Find records
    func findAllRecords<T>(onFound: @escaping ([T]) -> Void, iCloudRecordType: String = String(describing: T.self), onError: @escaping (Error) -> Void) {
        
        var results: [T] = []
        print ("🟢 Finding all '\(iCloudRecordType)' records")
 
        let query = CKQuery(recordType: iCloudRecordType, predicate: NSPredicate(value: true))

        let operation = CKQueryOperation(query: query)
        operation.zoneID = .default
        operation.resultsLimit = 200

        operation.recordFetchedBlock = { [self] record in
            DispatchQueue.main.sync {
                results.append(recordToResult(record: record) as! T)
            }
        }
        
        operation.queryCompletionBlock = {(cursor, error) in
//            print ("findAllRecords: \(results.count) records found")
            self.handleQueryCompletion(cursor: cursor, error: error, results: results, onFound: onFound, onError: onError)
        }
        iCloudDatabase.add(operation)
    }
    
    func fetchRecordByID<T>(recordID: CKRecord.ID, onFetched: @escaping (T) -> Void) {

        let iCloudRecordType = String(describing: T.self)       //Or "\(T.self)"
        print ("🟢 Finding '\(iCloudRecordType)' record with ID: \(recordID.recordName)")

        let operation = CKFetchRecordsOperation(recordIDs: [recordID])

        operation.perRecordCompletionBlock = { (record: CKRecord?, recordID: CKRecord.ID?, error: Error?) -> Void in
            DispatchQueue.main.sync {
                if error == nil {
                    guard let record = record else { return }
                    onFetched(self.recordToResult(record: record) as! T)
                } else {
                    self.handleCloudKitErrors(error: error)
                }
            }
        }
        iCloudDatabase.add(operation)
    }
    
    //MARK: - Update and Save new records
    
    func updateRecord<T>(from: T, record: CKRecord, onUpdated: @escaping (CKRecord.ID) -> Void ) {

        let iCloudRecordType = String(describing: T.self)
        print ("🟢 Updating \(iCloudRecordType)")

        saveRecord(record: record, onSaved: onUpdated)
    }
    
    func saveRecord<T>(from: T, record: CKRecord, onSaved: @escaping (CKRecord.ID) -> Void ) {
        let iCloudRecordType = String(describing: T.self)
        print ("Saving 1 \(iCloudRecordType) record type iCloudRecordType")
        
        saveRecord(record: record, onSaved: onSaved)
    }
    
    func saveRecords<T>(from: T, records: [CKRecord], onSaved: @escaping (CKRecord.ID?) -> Void ) {
        let iCloudRecordType = String(describing: T.self)
        print ("Saving \(records.count) \(iCloudRecordType) records")
        
        saveRecords(records: records, onSaved: onSaved)
    }
    
    func deleteRecords(records: [CKRecord.ID], onDeleted: @escaping () -> Void ) {

        print ("🟢 deleting records: \(records)")

        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: records)
        operation.savePolicy = .allKeys
        operation.modifyRecordsCompletionBlock = { added, deleted, error in
            DispatchQueue.main.sync {
                guard let deleted = deleted else { print ("❌ No records deleted"); return }
                if deleted.count != 1 {
                    print ("❌ Record NOT deleted. Why?")
                    return
                }
                if deleted.first != records.first {
                    print ("❌ Requested record NOT deleted. Why?")
                    return
                }
                if error == nil {
                    print ("Deleted record \(deleted.first!)")
                    onDeleted()
                } else {
                    self.handleCloudKitErrors(error: error)
                }
            }
        }
        iCloudDatabase.add(operation)
    }
    
    func deleteRecord(recordID: CKRecord.ID, onDeleted: @escaping () -> Void ) {
        print ("🟢 deleting record ID: \(recordID)")

        iCloudDatabase.delete(withRecordID: recordID) { (recordID, error) in
            DispatchQueue.main.sync {
                if recordID == nil {
                    print ("❌ Can't delete record!!")
                }
                if error == nil {
                    //Is it still there????
                    print ("Record says its deleted and returned NO error")
                    onDeleted()
                } else {
                    self.handleCloudKitErrors(error: error)
                }
            }
        }
    }
    
    private func saveRecord(record: CKRecord, onSaved: @escaping (CKRecord.ID) -> Void) {
//        print ("🟢 Saving record: \(record)")

        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        operation.savePolicy = .allKeys
        operation.modifyRecordsCompletionBlock = { added, deleted, error in
            DispatchQueue.main.sync {
                guard let added = added else { print ("❌ No records saved"); return }

                if added.count != 1 {
                    print ("❌ Record NOT saved. Error: \(error!)")
                    return
                }
                if added.first != added.first {
                    print ("❌ Requested record NOT saved. Error: \(error!)")
                    return
                }
                if error == nil {
//                    print ("✅ Saved record \(added.first!)")
                    onSaved(added.first!.recordID)
                } else {
                    print ("❌ Error saving record \(added.first!), error: \(error!)")
                    self.handleCloudKitErrors(error: error)
                }
            }
        }

        iCloudDatabase.add(operation)
    }
    
    private func saveRecords(records: [CKRecord], onSaved: @escaping (CKRecord.ID?) -> Void) {
//        print ("🟢 Saving \(records.count) records")

        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = .allKeys
        operation.modifyRecordsCompletionBlock = { added, deleted, error in
            DispatchQueue.main.sync {
                guard let added = added else { print ("❌ No records saved"); return }

                if added.count != records.count {
                    print ("❌ All records NOT saved. Why?")
                    return
                }
//                if self.recordIDsMatch(recordsToSave: records, recordsActuallySaved: added) {
//                    print ("❌ All requested records NOT saved. Why?")
//                    return
//                }
                if error == nil {
                    print ("✅ Saved \(added.count) records")
                    onSaved(added.count > 0 ? added.first!.recordID : nil)
                } else {
                    self.handleCloudKitErrors(error: error)
                }
            }
        }

        iCloudDatabase.add(operation)
    }
    
    // Override in subclass
    func recordToResult(record: CKRecord) -> Any? {
        return nil
    }

    private func handleQueryCompletion<T>(cursor: CKQueryOperation.Cursor?, error: Error?, results: [T], onFound: @escaping ([T]) -> Void, onError: @escaping (Error) -> Void) {
//        DispatchQueue.main.sync {
            if error == nil {
                onFound(results)
            } else {
                handleCloudKitErrors(error: error)
                onError(error!)
            }
//        }
    }

    private func handleCloudKitErrors(error: Error?) {
        if let errorCode = error as? CKError {
            print ("❌ Cloudkit error: \(errorCode)")
            switch errorCode.code {
                case .notAuthenticated, .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy, .resultsTruncated:
                    //Recoverable - retry
                    print ("❌ Recoverable database error \(errorCode.localizedDescription)")

                case .unknownItem, .invalidArguments, .incompatibleVersion, .badContainer, .missingEntitlement, .permissionFailure, .badDatabase, .assetFileNotFound, .operationCancelled, .assetFileModified, .batchRequestFailed, .zoneNotFound, .userDeletedZone, .internalError, .serverRejectedRequest, .constraintViolation:
                    //Fatal
                    print ("❌ Fatal database error \(errorCode.localizedDescription)")

                case .limitExceeded, .quotaExceeded, .changeTokenExpired,  .serverRecordChanged:
                    //Operational error
                    print ("❌ Operational database error \(errorCode.localizedDescription)")

                default:
                    print ("❌ Unknown database error \(errorCode.localizedDescription)")
            }
        }
    }
}
