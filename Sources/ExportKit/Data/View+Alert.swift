import SwiftUI

struct AlertView: ViewModifier {
    @State private var isPresented: Bool = false
    @Binding var type: AlertType?
    
    func body(content: Content) -> some View {
        content
            .onChange(of: type, perform: { newValue in
                isPresented = newValue != nil
            })
            .alert(isPresented: $isPresented) {
                Alert(title: Text(type?.title ?? "Error"),
                      message: Text(type?.description ?? "An error occured"),
                      dismissButton: Alert.Button.cancel({ type = nil }))
            }
    }
}


extension View {
    func alertView(type: Binding<AlertType?>) -> some View {
        modifier(AlertView(type: type))
    }
}

