import Foundation
import UIKit

class ExportViewModel: ObservableObject {
    @Published var data: [Item] = []
    @Published var alert: AlertType? = nil
    
    func load() {
        switch ExportKit.shared.getAllItems() {
        case .success(let items):
            data = items
        case.failure(let error):
            alert = .descriptiveError(error.localizedDescription)
        }
    }
        
    func export(item: Item) {
        guard let exportStrategy = ExportKit.shared.exportStrategy else {
            alert = .descriptiveError("No export strategy")
            ExportKit.shared.loggerCallback?("[ EXPORTER ] No export strategy")
            return
        }
        
        switch exportStrategy(item) {
        case .success(let itemToShare):
            let activityViewController = UIActivityViewController(activityItems: [itemToShare], applicationActivities: nil)
            UIApplication.topViewController()?.present(activityViewController, animated: true, completion: nil)
        case .failure(let error):
            alert = .descriptiveError(error.localizedDescription)
        }
    }
    
    func delete(at offsets: IndexSet) {
        offsets.forEach {
            if case let .failure(error) = ExportKit.shared.deleteItem(data[$0]) {
                alert = .descriptiveError(error.localizedDescription)
                return
            }
        }
        data.remove(atOffsets: offsets)
    }
}
