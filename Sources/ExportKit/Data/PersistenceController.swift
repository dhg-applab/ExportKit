import Foundation
import CoreData

final class PersistenceController {
    static let shared = PersistenceController()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let frameworkBundleIdentifier = "\(ExportKit.shared.config.appBundleIdentifier).ExportKit"
        guard let customKitBundle = Bundle(identifier: frameworkBundleIdentifier),
              let modelURL = customKitBundle.url(forResource: Constants.CoreData.containerName, withExtension: "momd"),
              let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            ExportKit.shared.loggerCallback?("[ FATAL ERROR - EXPORTER ] cannot load CoreData object model")
            fatalError("Unresolved error")
        }
        return managedObjectModel
    }()
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: Constants.CoreData.containerName, managedObjectModel: managedObjectModel)
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                ExportKit.shared.loggerCallback?("[ FATAL ERROR - EXPORTER ] \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
}
