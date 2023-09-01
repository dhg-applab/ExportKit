import SwiftUI

public struct ExportView: View {
    @StateObject var viewModel: ExportViewModel
    
    public var body: some View {
        List {
            if viewModel.data.isEmpty {
                Section {
                    EmptyView()
                } footer: {
                    HStack {
                        Spacer()
                        Text("No data found")
                        Spacer()
                    }
                }
            }
            
            ForEach(viewModel.data, id: \.id) { item in
                Button(action: { viewModel.export(item: item) }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .foregroundColor(.primary)
                            Text(item.id.uuidString)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text(item.type.description)
                            .foregroundColor(.green)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.green, lineWidth: 1)
                            )
                            .padding()
                        
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }.onDelete(perform: viewModel.delete(at:))
        }
        .onAppear(perform: viewModel.load)
        .alertView(type: $viewModel.alert)
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Export")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: viewModel.exportAll) {
                    Image(systemName: "square.and.arrow.up.on.square")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: viewModel.load) {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
        }
    }
}
