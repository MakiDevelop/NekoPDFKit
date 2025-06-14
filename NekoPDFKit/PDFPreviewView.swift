import SwiftUI
import PDFKit
import UIKit

struct PDFPreviewView: View {
    let pdfData: Data
    @State private var showingShareSheet = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            PDFKitView(pdfData: pdfData)
                .edgesIgnoringSafeArea(.all)
                .navigationTitle("PDF 預覽")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("關閉") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                .sheet(isPresented: $showingShareSheet) {
                    ShareSheet(items: [pdfData])
                }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

class CustomPDFView: PDFView {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let document = document, let page = document.page(at: 0) {
            let pageRect = page.bounds(for: .mediaBox)
            let viewRect = bounds
            let scaleX = viewRect.width / pageRect.width
            let scaleY = viewRect.height / pageRect.height
            let newScale = min(scaleX, scaleY)
            print("Layout updated - New scale factor: \(newScale)")
            scaleFactor = newScale
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let pdfData: Data
    
    func makeUIView(context: Context) -> CustomPDFView {
        print("Creating PDFKitView with data size: \(pdfData.count) bytes")
        let pdfView = CustomPDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true)
        pdfView.pageBreakMargins = .zero
        
        if let document = PDFDocument(data: pdfData) {
            print("Successfully created PDFDocument with \(document.pageCount) pages")
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: CustomPDFView, context: Context) {
        print("Updating PDFKitView")
        if let document = pdfView.document {
            print("Updating PDFDocument with \(document.pageCount) pages")
        }
    }
} 