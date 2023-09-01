import SwiftUI
import CoreData

public enum ExportKitError: Error {
    case couldNotSave(reason: String)
    case fetchError(reason: String)
    case itemNotFound
    case unkownError
    case fetchRequestNil
}

public struct ExportKitItem {
    public let type: DataType
    public let name: String
    public let id: UUID
    public let timestamp: Double
    public let managedObject: NSManagedObject
    public var children: [NSManagedObject]?
}

public class ExportKit {
    
    public static var shared = ExportKit()
    public var exportStrategy: ((ExportKitItem?) -> Result<Any, Error>)?
    public var logHandler: ((String) -> Void)?
    public static var view: ExportView {
        ExportView(viewModel: ExportViewModel())
    }
    public static var fetchRequest: NSFetchRequest<NSFetchRequestResult> {
        NSFetchRequest<NSFetchRequestResult>(entityName: Constants.CoreData.entryName)
    }
    
    // MARK: - CRUD
    public func createItem(name: String) -> Item {
        let item = Item(context: PersistenceController.shared.backgroundContext)
        item.id = UUID()
        item.name = name
        item.timestamp = Date()
        return item
    }
    
    @discardableResult
    public func save() -> Result<Void, ExportKitError> {
        do {
            try PersistenceController.shared.backgroundContext.save()
        } catch {
            ExportKit.shared.logHandler?("[ ERROR - EXPORTER ] Could not save data \(error)")
            return .failure(.couldNotSave(reason: error.localizedDescription))
        }
        return .success(())
    }
    
    public func getAllItems() -> Result<[ExportKitItem], ExportKitError> {
        let request = ExportKit.fetchRequest
        let items = getItems(fetchRequest: request)
        let itemGroups = getItemGroups()
        
        if case let .failure(failure) = items,
           case let .failure(failure) = itemGroups {
            return .failure(failure)
        }
        
        
        guard case let .success(items) = items,
              case let .success(itemGroups) = itemGroups else { return .failure(.unkownError) }
        
        
        var exportKitItems: [ExportKitItem] = []

        items.forEach { item in
            guard let name = item.name,
                  let id = item.id,
                  let timestamp = item.timestamp?.timeIntervalSince1970 else { return }
            exportKitItems.append(.init(type: .single, name: name, id: id, timestamp: timestamp, managedObject: item, children: nil))
        }
        
        itemGroups.forEach { itemGroup in
            guard let name = itemGroup.name,
                  let id = itemGroup.id else { return }
            exportKitItems.append(.init(type: .group, name: name, id: id, timestamp: itemGroup.startTimestamp, managedObject: itemGroup, children: nil))
        }
        
        return .success(exportKitItems)
    }
    
    public func getItem(id: UUID) -> Result<Item, ExportKitError> {
        let request = ExportKit.fetchRequest
        request.predicate = NSPredicate(format: "id == %@", id.uuidString)
        
        switch getItems(fetchRequest: request) {
        case .success(let items):
            if items.count == 1,
               let item = items.first {
                return .success(item)
            } else {
                return .failure(.itemNotFound)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func getItems(predicate: NSPredicate) -> Result<[Item], ExportKitError> {
        let request = ExportKit.fetchRequest
        request.predicate = predicate
        return getItems(fetchRequest: request)
    }
    
    public func getItems(fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> Result<[Item], ExportKitError> {
        do {
            if let data = try PersistenceController.shared.backgroundContext.fetch(fetchRequest) as? [Item] {
                return .success(data)
            } else {
                return .failure(.fetchRequestNil)
            }
        } catch {
            ExportKit.shared.logHandler?("[ ERROR - EXPORTER ] Could not save data \(error)")
            return .failure(.fetchError(reason: error.localizedDescription))
        }
    }
    
    @discardableResult
    public func deleteItem(id: UUID) -> Result<Void, ExportKitError> {
        switch getItem(id: id) {
        case .success(let item):
            return deleteItem(item)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @discardableResult
    public func deleteItem(_ item: Item) -> Result<Void, ExportKitError> {
        PersistenceController.shared.backgroundContext.delete(item)
        return save()
    }
    
    public func delete(_ object: NSManagedObject) -> Result<Void, ExportKitError> {
        PersistenceController.shared.backgroundContext.delete(object)
        return save()
    }
    
    @discardableResult
    public func deleteAllItems() -> Result<Void, ExportKitError> {
        guard case let .success(allItems) = getAllItems() else {
            return .failure(.unkownError)
        }
        allItems.forEach { PersistenceController.shared.backgroundContext.delete($0.managedObject) }
        return save()
    }
    
    // To make the client feature complete
    @available(*, unavailable, message: "Just use getItem(id:), update the item and call save()")
    public func updateItem(_ item: Item) -> Result<Void, ExportKitError> {
        .success(())
    }
}

// MARK: - ItemGroup
extension ExportKit {
    public func getItemGroups() -> Result<[ItemGroup], ExportKitError> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ItemGroup")
        do {
            guard let data = try PersistenceController.shared.backgroundContext.fetch(request) as? [ItemGroup] else { return .success([]) }
            return .success(data)
        } catch {
            return .failure(.fetchError(reason: error.localizedDescription))
        }
    }
    
    public func getGroupedItems(for id: UUID) -> Result<[GroupedItem], ExportKitError> {
        let groupedItemRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "GroupedItem")
        groupedItemRequest.predicate = NSPredicate(format: "itemGroupID == %@", id.uuidString)
        do {
            guard let data = try PersistenceController.shared.backgroundContext.fetch(groupedItemRequest) as? [GroupedItem] else { return .success([]) }
            return .success(data)
        } catch {
            return .failure(.fetchError(reason: error.localizedDescription))
        }
    }
    
    public func getGroupedItems(for itemGroup: ItemGroup) -> Result<[GroupedItem], ExportKitError> {
        guard let id = itemGroup.id else { return .failure(.fetchError(reason: "ItemGroup does not have an ID"))}
        return getGroupedItems(for: id)
    }
    
    
    public func deleteItemGroup(_ itemGroup: ItemGroup) -> Result<Void, ExportKitError> {
        guard let id = itemGroup.id else { return .failure(.fetchError(reason: "ItemGroup does not have an ID")) }
        
        do {
            let result = getGroupedItems(for: id)
            
            if case let .failure(failure) = result {
                return .failure(failure)
            }
            
            guard case let .success(data) = result else { return .failure(.unkownError) }
            
            data.forEach { PersistenceController.shared.backgroundContext.delete($0) }
            PersistenceController.shared.backgroundContext.delete(itemGroup)
            
            try PersistenceController.shared.backgroundContext.save()
            
            return .success(())
        } catch {
            return .failure(.fetchError(reason: error.localizedDescription))
        }
    }
    
    public func createItemGroup(name: String, startTimestamp: TimeInterval? = nil) -> ItemGroup {
        let itemGroup = ItemGroup(context: PersistenceController.shared.backgroundContext)
        
        itemGroup.id = UUID()
        itemGroup.name = name
        itemGroup.startTimestamp = startTimestamp ?? Date().timeIntervalSince1970
        
        try? PersistenceController.shared.backgroundContext.save()
        
        return itemGroup
    }
    
    @discardableResult
    public func batchInsert(_ data: [Data], to itemGroup: ItemGroup) -> Bool {
        guard !data.isEmpty else { return false }

        let batchInsertRequest = newBatchInsertRequest(with: data, to: itemGroup)
        
        if let fetchResult = try? PersistenceController.shared.backgroundContext.execute(batchInsertRequest),
           let batchInsertResult = fetchResult as? NSBatchInsertResult,
           let success = batchInsertResult.result as? Bool,
           ((try? PersistenceController.shared.backgroundContext.save()) != nil) {
            return success
        }
        return false
    }

    private func newBatchInsertRequest(with groupedItems: [Data], to itemGroup: ItemGroup) -> NSBatchInsertRequest {
        var index = 0
        let total = groupedItems.count

        let batchInsert = NSBatchInsertRequest(entityName: "GroupedItem") { (managedObject: NSManagedObject) -> Bool in
            guard index < total else { return true }
            
            if let groupedItem = managedObject as? GroupedItem {
                let data = groupedItems[index]
                groupedItem.id = UUID()
                groupedItem.data = data
                groupedItem.itemGroupID = itemGroup.id!
            }

            index += 1
            return false
        }
        return batchInsert
    }
}
