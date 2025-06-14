import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct PDFMergeView: View {
    @State private var selectedPDFs: [PDFDocument] = []
    @State private var showingPDFPicker = false
    @State private var showingPDFPreview = false
    @State private var mergedPDFData: Data?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                if selectedPDFs.isEmpty {
                    ContentUnavailableView {
                        Label("沒有PDF", systemImage: "doc.fill")
                    } description: {
                        Text("點擊下方按鈕選擇PDF")
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
                        ], spacing: 16) {
                            ForEach(0..<selectedPDFs.count, id: \.self) { index in
                                PDFPreviewCell(pdf: selectedPDFs[index])
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            selectedPDFs.remove(at: index)
                                        } label: {
                                            Label("刪除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        showingPDFPicker = true
                    }) {
                        Label("選擇PDF", systemImage: "doc.fill")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    if !selectedPDFs.isEmpty {
                        Button(action: {
                            generateAndShowPDF()
                        }) {
                            Label("預覽PDF", systemImage: "doc.fill")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(isGenerating)
                    }
                }
                .padding()
            }
            .navigationTitle("PDF合併")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPDFPicker) {
                PDFPickerView(selectedPDFs: $selectedPDFs)
            }
            .sheet(isPresented: $showingPDFPreview) {
                if let data = mergedPDFData {
                    PDFPreviewView(pdfData: data)
                }
            }
            .alert("錯誤", isPresented: .constant(errorMessage != nil)) {
                Button("確定") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private func generateAndShowPDF() {
        isGenerating = true
        errorMessage = nil
        
        // 創建新的 PDF 文檔
        let mergedPDF = PDFDocument()
        
        // 遍歷所有選中的 PDF
        for pdf in selectedPDFs {
            // 遍歷當前 PDF 的所有頁面
            for i in 0..<pdf.pageCount {
                if let page = pdf.page(at: i) {
                    mergedPDF.insert(page, at: mergedPDF.pageCount)
                }
            }
        }
        
        // 生成合併後的 PDF 數據
        if let data = mergedPDF.dataRepresentation() {
            mergedPDFData = data
            showingPDFPreview = true
        } else {
            errorMessage = "無法生成合併的PDF"
        }
        
        isGenerating = false
    }
}

struct PDFPreviewCell: View {
    let pdf: PDFDocument
    
    var body: some View {
        VStack {
            if let page = pdf.page(at: 0) {
                PDFPageView(page: page)
                    .frame(height: 200)
                    .cornerRadius(8)
            }
            Text("PDF文件")
                .font(.caption)
        }
    }
}

struct PDFPageView: UIViewRepresentable {
    let page: PDFPage
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true)
        pdfView.pageBreakMargins = .zero
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = PDFDocument()
        pdfView.document?.insert(page, at: 0)
    }
}

struct PDFPickerView: UIViewControllerRepresentable {
    @Binding var selectedPDFs: [PDFDocument]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [.pdf]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        picker.shouldShowFileExtensions = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: PDFPickerView
        
        init(_ parent: PDFPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            print("Selected PDF files: \(urls.count)")
            
            for url in urls {
                print("Processing PDF file: \(url.lastPathComponent)")
                
                // 確保文件存在
                guard FileManager.default.fileExists(atPath: url.path) else {
                    print("File does not exist: \(url.path)")
                    continue
                }
                
                // 嘗試讀取 PDF
                do {
                    let data = try Data(contentsOf: url)
                    if let pdf = PDFDocument(data: data) {
                        print("Successfully loaded PDF: \(url.lastPathComponent) with \(pdf.pageCount) pages")
                        parent.selectedPDFs.append(pdf)
                    } else {
                        print("Failed to create PDFDocument from data: \(url.lastPathComponent)")
                    }
                } catch {
                    print("Error reading PDF file: \(error.localizedDescription)")
                }
            }
            
            print("Total PDFs loaded: \(parent.selectedPDFs.count)")
            parent.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("PDF picker was cancelled")
            parent.dismiss()
        }
    }
} 