import SwiftUI

enum AlertType: Equatable {
    case critical
    case descriptiveError(String)
    
    
    var title: String {
        switch self {
        case .critical:
            return "Critical Error"
        case .descriptiveError:
            return "Error"
        }
    }
    
    var description: String {
        switch self {
        case .critical:
            return "A critical error occured."
        case .descriptiveError(let description):
            return description
        }
    }
}
