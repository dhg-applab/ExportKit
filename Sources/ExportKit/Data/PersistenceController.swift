import Foundation
import CoreData

final class PersistenceController {
    static let shared = PersistenceController()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        guard let modelURL = Bundle.module.url(forResource: Constants.CoreData.containerName, withExtension: "momd"),
              let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            ExportKit.shared.logHandler?("[ FATAL ERROR - ExportKit ] cannot load CoreData object model")
            fatalError("Unresolved error")
        }
        return managedObjectModel
    }()
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: Constants.CoreData.containerName, managedObjectModel: managedObjectModel)
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                ExportKit.shared.logHandler?("[ FATAL ERROR - ExportKit ] \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
}
