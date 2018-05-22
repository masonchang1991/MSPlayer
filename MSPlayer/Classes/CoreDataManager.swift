//
//  CoreDataManager.swift
//  MSPlayer
//
//  Created by Mason on 2018/5/21.
//

import Foundation
import CoreData

open class MSCoreDataManager {
    
    fileprivate func save(managedContext: NSManagedObjectContext) {
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
}

extension MSCoreDataManager {
    
    func saveVideoTimeRecordWith(_ videoId: String, videoTime: TimeInterval) {
        let managedContext = MSPM.shared().managedObjectContext
        let entity = NSEntityDescription.entity(forEntityName: "VideoTimeRecord",
                                                in: managedContext)!
        // 先看看 CoreData 裡面是否有此筆資料
        let isUpdateRecord = checkIfNeedToUpdateWith(context: managedContext, videoId: videoId, videoTime: videoTime)
        
        if !isUpdateRecord {
            //如果不是執行 Update 代表 CoreData 內沒有這個資料，所以新增資料
            let videoTimeRecord = VideoTimeRecord(entity: entity, insertInto: managedContext)
            videoTimeRecord.recordID = videoId
            videoTimeRecord.timeRecord = videoTime
            // 判斷目前是否已經達到三十筆，如果是，則刪除尾項
            if loadVideoTimeRecords().count >= MSPM.shared().recordVideoTimeNumber {
                deleteLastVideoTimeRecord()
            }
            // 將資料寫入資料庫
            self.save(managedContext: managedContext)
        }
    }
    
    func checkIfNeedToUpdateWith(context: NSManagedObjectContext, videoId: String, videoTime: TimeInterval) -> Bool {
        let fetchRequest = NSFetchRequest<VideoTimeRecord>(entityName: "VideoTimeRecord")
        var fetchResult = [VideoTimeRecord]()
        do {
            // 先看看 CoreData 裡面是否有此筆資料，有的話執行更新資料
            fetchResult = try context.fetch(fetchRequest)
            for record in fetchResult {
                if record.recordID == videoId {
                    record.timeRecord = videoTime
                    self.save(managedContext: context)
                    return true
                }
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return false
    }
    
    func loadVideoTimeRecordWith(_ videoId: String, completion: @escaping ((Double?) -> Void)) {
        let fetchResult = loadVideoTimeRecords()
        for videoRecord in fetchResult {
            if let id = videoRecord.recordID  {
                if id == videoId {
                    completion(videoRecord.timeRecord)
                    return
                }
            }
        }
        completion(nil)
    }
    
    fileprivate func loadVideoTimeRecords() -> [VideoTimeRecord] {
        let managedContext = MSPM.shared().managedObjectContext
        let fetchRequest = NSFetchRequest<VideoTimeRecord>(entityName: "VideoTimeRecord")
        var fetchResult = [VideoTimeRecord]()
        do {
            fetchResult = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return fetchResult
    }
    
    func deleteLastVideoTimeRecord() {
        let managedContext = MSPM.shared().managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VideoTimeRecord")
        fetchRequest.returnsObjectsAsFaults = false
        
        //先刪除這個看板之前的瀏覽記錄
        do {
            let managedObject = try managedContext.fetch(fetchRequest).last
            let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
            managedContext.delete(managedObjectData)
            try managedContext.save()
        } catch let error as NSError {
            print("Detele all data in SearchHistory error : \(error)")
        }
    }
    
    func deleteVideoTimeRecordWith(_ videoId: String) {
        let managedContext = MSPM.shared().managedObjectContext
        let fetchRequest = NSFetchRequest<VideoTimeRecord>(entityName: "VideoTimeRecord")
        fetchRequest.returnsObjectsAsFaults = false
        var fetchResults = [VideoTimeRecord]()
        do {
            fetchResults = try managedContext.fetch(fetchRequest)
            for result in fetchResults {
                if result.recordID == videoId {
                    let managedObjectData: NSManagedObject = result
                    managedContext.delete(managedObjectData)
                }
            }
        } catch let error as NSError {
            print("Delete video by videoId in VideoTimeRecord error: \(error)")
        }
    }
    
    func deleteAllVideoTimeRecords() {
        let managedContext = MSPM.shared().managedObjectContext
        let fetchRequest = NSFetchRequest<VideoTimeRecord>(entityName: "VideoTimeRecord")
        fetchRequest.returnsObjectsAsFaults = false
        var fetchResults = [VideoTimeRecord]()
        do {
            fetchResults = try managedContext.fetch(fetchRequest)
            for result in fetchResults {
                let managedObjectData: NSManagedObject = result
                managedContext.delete(managedObjectData)
            }
        } catch let error as NSError {
            print("Delete video by videoId in VideoTimeRecord error: \(error)")
        }
    }
}

