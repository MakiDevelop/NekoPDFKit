import SwiftUI
import PDFKit
import UIKit

enum PDFError: Error {
    case generationFailed
    case invalidData
}

class PDFExportService {
    static func generatePDF(from images: [UIImage], completion: @escaping (Result<Data, Error>) -> Void) {
        print("Starting PDF generation with \(images.count) images")
        
        // 使用 A4 尺寸 (595 x 842 points)
        let pageSize = CGSize(width: 595, height: 842)
        let pageRect = CGRect(origin: .zero, size: pageSize)
        
        // 創建 PDF 上下文
        let pdfMetaData = [
            kCGPDFContextCreator: "NekoPDFKit",
            kCGPDFContextAuthor: "NekoPDFKit User",
            kCGPDFContextTitle: "Generated PDF"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            print("Creating PDF context with page size: \(pageRect)")
            
            // 使用 autoreleasepool 來管理內存
            autoreleasepool {
                for (index, image) in images.enumerated() {
                    print("Processing image \(index + 1) of \(images.count)")
                    
                    context.beginPage()
                    
                    // 計算圖片在頁面中的位置和大小
                    let imageSize = image.size
                    
                    // 設置邊距
                    let margin: CGFloat = 40
                    let maxWidth = pageSize.width - (margin * 2)
                    let maxHeight = pageSize.height - (margin * 2)
                    
                    // 計算適合的尺寸
                    var imageRect: CGRect
                    
                    // 計算基於寬度和高度的縮放比例
                    let widthScale = maxWidth / imageSize.width
                    let heightScale = maxHeight / imageSize.height
                    
                    // 使用較小的縮放比例以確保圖片完全適應頁面
                    let scale = min(widthScale, heightScale)
                    
                    // 計算新的尺寸
                    let newWidth = imageSize.width * scale
                    let newHeight = imageSize.height * scale
                    
                    // 計算居中位置
                    let x = (pageSize.width - newWidth) / 2
                    let y = (pageSize.height - newHeight) / 2
                    
                    imageRect = CGRect(x: x, y: y, width: newWidth, height: newHeight)
                    
                    print("Drawing image \(index + 1) in rect: \(imageRect)")
                    
                    // 使用高質量繪製
                    image.draw(in: imageRect)
                }
            }
        }
        
        // 驗證 PDF
        if let pdfDocument = PDFDocument(data: data) {
            let pageCount = pdfDocument.pageCount
            print("PDF generation completed. Data size: \(data.count) bytes")
            print("PDF validation successful: \(pageCount) pages")
            completion(.success(data))
        } else {
            print("PDF validation failed")
            completion(.failure(NSError(domain: "PDFExport", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to validate PDF"])))
        }
    }
} 