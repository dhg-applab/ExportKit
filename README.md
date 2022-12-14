# ExportKit

A simple package to save and export data in the app. The package also includes simple views to list all saved data and export them using the [ShareSheet](https://developer.apple.com/documentation/uikit/uiactivityviewcontroller). 


### Setup
To export data, ExportKit needs an `exportStrategy` which need to be defined before exporting the data. 
For UIKit apps you can set the strategy in the [App Delegate](https://developer.apple.com/documentation/uikit/uiapplicationdelegate), SwiftUI apps can make use root view (where `:App` is defiend).

```
ExportKit.shared.exportStrategy = { item in
    guard let item = item else { 
        return .failure(ExportKitError.itemNotFound) 
    }
    
    *** DO SOMETHING WITH THE ITEM *** 
    
    return .success(DATA_TO_BE_SHARED)
}
```
