import SwiftUI
import PDFKit
import PhotosUI

// 1. 統一的數據模型
enum MergeableItem: Identifiable, Hashable {
    case image(UIImage)
    case pdf(PDFDocument)

    var id: String {
        switch self {
        case .image(let image):
            return image.hash.description
        case .pdf(let pdf):
            // PDFDocument 沒有內置的 hash，我們用頁數和第一個頁面的 hash 作為一個簡單的標識
            return "pdf-\(pdf.pageCount)-\(pdf.page(at: 0)?.hash ?? 0)"
        }
    }
    
    // 為了讓 PDFDocument 可 Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MergeableItem, rhs: MergeableItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct MergeView: View {
    @State private var items: [MergeableItem] = []
    @State private var showingFileImporter = false
    @State private var showingPhotosPicker = false
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var showingPDFPreview = false
    @State private var mergedPDFData: Data?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                if items.isEmpty {
                    ContentUnavailableView("無項目", systemImage: "doc.on.doc", description: Text("點擊下方按鈕添加圖片或 PDF"))
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)], spacing: 16) {
                            ForEach(items) { item in
                                MergeItemView(item: item)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            items.removeAll { $0.id == item.id }
                                        } label: {
                                            Label("刪除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
                
                bottomButtons
            }
            .navigationTitle("合併文件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("關閉") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: true
            ) { result in
                handleFileImporterResult(result)
            }
            .sheet(isPresented: $showingPDFPreview) {
                if let data = mergedPDFData {
                    PDFPreviewView(pdfData: data)
                }
            }
            .alert("錯誤", isPresented: .constant(errorMessage != nil)) {
                Button("確定") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .padding()
            .photosPicker(
                isPresented: $showingPhotosPicker,
                selection: $photoPickerItems,
                matching: .images
            )
            .onChange(of: photoPickerItems) { _, newItems in
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            items.append(.image(image))
                        }
                    }
                    photoPickerItems = []
                }
            }
        }
    }

    private var bottomButtons: some View {
        VStack(spacing: 12) {
             Menu {
                Button(action: { showingPhotosPicker = true }) {
                    Label("從照片選擇", systemImage: "photo")
                }
                Button(action: { showingFileImporter = true }) {
                    Label("從文件選擇", systemImage: "folder")
                }
            } label: {
                Label("添加項目", systemImage: "plus")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            if !items.isEmpty {
                Button(action: generateAndShowPDF) {
                    Label("合併並預覽", systemImage: "doc.text.magnifyingglass")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isGenerating ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isGenerating)

                Button(action: {
                    withAnimation {
                        items.removeAll()
                    }
                }) {
                    Label("清除全部", systemImage: "trash")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }

    private func handleFileImporterResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                let didAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if didAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType, type.conforms(to: .pdf) {
                    if let pdf = PDFDocument(url: url) {
                        items.append(.pdf(pdf))
                    }
                } else if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType, type.conforms(to: .image) {
                     if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        items.append(.image(image))
                    }
                }
            }
        case .failure(let error):
            errorMessage = "無法讀取文件: \(error.localizedDescription)"
        }
    }

    private func generateAndShowPDF() {
        isGenerating = true
        let mergedPDF = PDFDocument()
        
        for item in items {
            switch item {
            case .image(let image):
                if let page = PDFPage(image: image) {
                    mergedPDF.insert(page, at: mergedPDF.pageCount)
                }
            case .pdf(let pdf):
                for i in 0..<pdf.pageCount {
                    if let page = pdf.page(at: i) {
                        mergedPDF.insert(page, at: mergedPDF.pageCount)
                    }
                }
            }
        }

        if let data = mergedPDF.dataRepresentation() {
            mergedPDFData = data
            showingPDFPreview = true
        } else {
            errorMessage = "無法生成合併的PDF"
        }
        
        isGenerating = false
    }
}

// 預覽縮略圖的視圖
struct MergeItemView: View {
    let item: MergeableItem
    
    var body: some View {
        VStack {
            switch item {
            case .image(let image):
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
            case .pdf(let pdf):
                if let page = pdf.page(at: 0) {
                    PDFPageView(page: page)
                        .frame(height: 200)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                }
            }
            
            Text(itemTypeDescription)
                .font(.caption)
        }
    }

    private var itemTypeDescription: String {
        switch item {
        case .image:
            return "圖片"
        case .pdf(let pdf):
            return "PDF (\(pdf.pageCount)頁)"
        }
    }
}

// PDF 縮略圖視圖
struct PDFPageView: UIViewRepresentable {
    let page: PDFPage
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.pageBreakMargins = .zero
        pdfView.backgroundColor = .clear
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        let doc = PDFDocument()
        doc.insert(page, at: 0)
        pdfView.document = doc
    }
}

#Preview {
    MergeView()
} 