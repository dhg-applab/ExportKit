import Foundation
import UIKit

public enum DataType: CustomStringConvertible, CaseIterable {
    case single
    case group
    
    public var description: String {
        switch self {
        case .single:
            return "Single"
        case .group:
            return "Group"
        }
    }
}

class ExportViewModel: ObservableObject {
    @Published var data: [ExportKitItem] = []
    @Published var alert: AlertType? = nil
    
    func load() {
        switch ExportKit.shared.getAllItems() {
        case .success(let items):
            data = items
        case.failure(let error):
            alert = .descriptiveError(error.localizedDescription)
        }
    }
        
    func export(item: ExportKitItem) {
        var item = item
        guard let exportStrategy = ExportKit.shared.exportStrategy else {
            alert = .descriptiveError("No export strategy")
            ExportKit.shared.logHandler?("[ EXPORTER ] No export strategy")
            return
        }
        
        guard let topViewController = UIApplication.topViewController() else {
            alert = .descriptiveError("No Top View Controller")
            ExportKit.shared.logHandler?("[ EXPORTER ] No Top View Controller")
            return
        }
        
        if item.type == .group {
            switch ExportKit.shared.getGroupedItems(for: item.id) {
            case .success(let items):
                item.children = items
            case .failure(let error):
                alert = .descriptiveError(error.localizedDescription)
            }
        }
        
        switch exportStrategy(item) {
        case .success(let itemToShare):
            let activityViewController = UIActivityViewController(activityItems: [itemToShare], applicationActivities: nil)
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                activityViewController.popoverPresentationController?.sourceView = topViewController.view
                activityViewController.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                activityViewController.popoverPresentationController?.permittedArrowDirections = []
            }
            topViewController.present(activityViewController, animated: true, completion: nil)
        case .failure(let error):
            alert = .descriptiveError(error.localizedDescription)
        }
    }

    func exportAll() {
        guard let exportStrategy = ExportKit.shared.exportStrategy else {
            alert = .descriptiveError("No export strategy")
            ExportKit.shared.logHandler?("[ EXPORTER ] No export strategy")
            return
        }

        guard let topViewController = UIApplication.topViewController() else {
            alert = .descriptiveError("No Top View Controller")
            ExportKit.shared.logHandler?("[ EXPORTER ] No Top View Controller")
            return
        }

//        let results = data.reduce(.success([ExportKitItem]())) { (partialResult, item) -> Result<[Any], Error> in
//            switch partialResult {
//            case .failure(_):
//                return partialResult
//            case .success(let array):
//                switch exportStrategy(item) {
//                case .success(let itemResult):
//                    return .success(array + CollectionOfOne(itemResult))
//                case .failure(let error):
//                    return .failure(error)
//                }
//            }
//        }

//        switch results {
//        case .success(let items):
//            var itemsToShare = [Any]()
//
//            if let textItems = items as? [String] {
//                let textToShare = textItems.reduce("") { partialResult, item in
//                    if partialResult.isEmpty {
//                        return item
//                    } else {
//                        return partialResult + "\n" + item
//                    }
//                }
//                itemsToShare.append(textToShare)
//            } else {
//                itemsToShare.append(items)
//            }
//
//            let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
//
//            if UIDevice.current.userInterfaceIdiom == .pad {
//                activityViewController.popoverPresentationController?.sourceView = topViewController.view
//                activityViewController.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
//                activityViewController.popoverPresentationController?.permittedArrowDirections = []
//            }
//            topViewController.present(activityViewController, animated: true, completion: nil)
//        case .failure(let error):
//            alert = .descriptiveError(error.localizedDescription)
//        }
    }
    
    func delete(at offsets: IndexSet) {
        offsets.forEach {
            if case let .failure(error) = ExportKit.shared.delete(data[$0].managedObject) {
                alert = .descriptiveError(error.localizedDescription)
                return
            }
        }
        data.remove(atOffsets: offsets)
    }
}
