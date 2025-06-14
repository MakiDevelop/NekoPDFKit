import SwiftUI

struct ImageItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct PreviewGridView: View {
    @Binding var images: [UIImage]
    @State private var draggedItem: ImageItem?
    
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 10)
    ]
    
    private var imageItems: [ImageItem] {
        images.map { ImageItem(image: $0) }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(imageItems) { item in
                    Image(uiImage: item.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .onDrag {
                            draggedItem = item
                            return NSItemProvider(object: item.image)
                        }
                        .onDrop(of: [.image], delegate: DropViewDelegate(item: item, items: $images, draggedItem: $draggedItem))
                        .contextMenu {
                            Button(role: .destructive) {
                                if let index = images.firstIndex(where: { $0 === item.image }) {
                                    images.remove(at: index)
                                }
                            } label: {
                                Label("刪除", systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
            .animation(.default, value: images)
        }
    }
}

struct DropViewDelegate: DropDelegate {
    let item: ImageItem
    @Binding var items: [UIImage]
    @Binding var draggedItem: ImageItem?
    
    func performDrop(info: DropInfo) -> Bool {
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem else { return }
        
        if draggedItem.id != item.id {
            let from = items.firstIndex(where: { $0 === draggedItem.image })!
            let to = items.firstIndex(where: { $0 === item.image })!
            
            if items[to] !== draggedItem.image {
                let item = items.remove(at: from)
                items.insert(item, at: to)
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
} 