import SwiftUI
import CoreData

public enum ExporterClientError: Error {
    case couldNotSave(reason: String)
    case fetchError(reason: String)
    case itemNotFound
    case unkownError
    case fetchRequestNil
}

public struct ExportKitConfig {
    let appBundleIdentifier: String
}

public class ExportKit {
    
    public static var shared: ExportKit {
        if let initializedShared = _shared {
            return initializedShared
        }
        fatalError("ExportKit not yet initialized. Run setup(withConfig:) first")
    }
    private static var _shared: ExportKit?
    var config: ExportKitConfig
    public var exportStrategy: ((Item?) -> Result<Any, Error>)?
    public var loggerCallback: ((String) -> Void)?
    public static var view: ExportView {
        ExportView(viewModel: ExportViewModel())
    }
    public static var fetchRequest: NSFetchRequest<NSFetchRequestResult> {
        NSFetchRequest<NSFetchRequestResult>(entityName: Constants.CoreData.entryName)
    }
    
    // MARK: - Init
    private init(withConfig config: ExportKitConfig) {
        self.config = config
    }
    
    class func setup(withConfig config: ExportKitConfig) {
        _shared = ExportKit(withConfig: config)
    }
    
    // MARK: - CRUD
    public func createItem(name: String) -> Item {
        let item = Item(context: PersistenceController.shared.container.viewContext)
        item.id = UUID()
        item.name = name
        item.timestamp = Date()
        return item
    }
    
    @discardableResult
    public func save() -> Result<Void, ExporterClientError> {
        do {
            try PersistenceController.shared.container.viewContext.save()
        } catch {
            ExportKit.shared.loggerCallback?("[ ERROR - EXPORTER ] Could not save data \(error)")
            return .failure(.couldNotSave(reason: error.localizedDescription))
        }
        return .success(())
    }
    
    public func getItem(id: UUID) -> Result<Item, ExporterClientError> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.CoreData.entryName)
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
    
    public func getItems(predicate: NSPredicate) -> Result<[Item], ExporterClientError> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.CoreData.entryName)
        request.predicate = predicate
        return getItems(fetchRequest: request)
    }
    
    public func getAllItems() -> Result<[Item], ExporterClientError> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.CoreData.entryName)
        return getItems(fetchRequest: request)
    }
    
    public func getItems(fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> Result<[Item], ExporterClientError> {
        do {
            if let data = try PersistenceController.shared.container.viewContext.fetch(fetchRequest) as? [Item] {
                return .success(data)
            } else {
                return .failure(.fetchRequestNil)
            }
        } catch {
            ExportKit.shared.loggerCallback?("[ ERROR - EXPORTER ] Could not save data \(error)")
            return .failure(.fetchError(reason: error.localizedDescription))
        }
    }
    
    @discardableResult
    public func deleteItem(id: UUID) -> Result<Void, ExporterClientError> {
        switch getItem(id: id) {
        case .success(let item):
            return deleteItem(item)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    @discardableResult
    public func deleteItem(_ item: Item) -> Result<Void, ExporterClientError> {
        PersistenceController.shared.container.viewContext.delete(item)
        return save()
    }
    
    @discardableResult
    public func deleteAllItems() -> Result<Void, ExporterClientError> {
        guard case let .success(allItems) = getAllItems() else {
            return .failure(.unkownError)
        }
        allItems.forEach { PersistenceController.shared.container.viewContext.delete($0) }
        return save()
    }
    
    // To make the client feature complete
    @available(*, unavailable, message: "Just use getItem(id:), update the item and call save()")
    public func updateItem(_ item: Item) -> Result<Void, ExporterClientError> {
        .success(())
    }
}
