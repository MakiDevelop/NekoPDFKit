//
//  ContentView.swift
//  NekoPDFKit
//
//  Created by 千葉牧人 on 2025/6/14.
//

import SwiftUI
import PhotosUI
import PDFKit

class PDFState: ObservableObject {
    @Published var pdfData: Data?
    @Published var isGenerating = false
    @Published var error: Error?
    
    func generatePDF(from images: [UIImage]) {
        isGenerating = true
        error = nil
        
        PDFExportService.generatePDF(from: images) { [weak self] result in
            DispatchQueue.main.async {
                self?.isGenerating = false
                switch result {
                case .success(let data):
                    print("PDF generation successful, data size: \(data.count) bytes")
                    self?.pdfData = data
                case .failure(let error):
                    print("PDF generation failed: \(error.localizedDescription)")
                    self?.error = error
                }
            }
        }
    }
}

struct ContentView: View {
    @State private var selectedImages: [UIImage] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingPDFPreview = false
    @State private var pdfData: Data?
    @State private var isGenerating = false
    @State private var showingPDFMerge = false
    @StateObject private var pdfState = PDFState()
    
    var body: some View {
        NavigationStack {
            VStack {
                if selectedImages.isEmpty {
                    ContentUnavailableView {
                        Label("沒有圖片", systemImage: "photo.fill")
                    } description: {
                        Text("點擊下方按鈕選擇圖片")
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 16)
                        ], spacing: 16) {
                            ForEach(0..<selectedImages.count, id: \.self) { index in
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            selectedImages.remove(at: index)
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
                    PhotosPicker(selection: $selectedItems,
                               maxSelectionCount: 0,
                               matching: .images) {
                        Label("選擇圖片", systemImage: "photo.fill")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .onChange(of: selectedItems) { oldValue, newItems in
                        Task {
                            var images: [UIImage] = []
                            for item in newItems {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    images.append(image)
                                }
                            }
                            selectedImages.append(contentsOf: images)
                            selectedItems.removeAll()
                        }
                    }
                    
                    if !selectedImages.isEmpty {
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
                
                Button(action: {
                    showingPDFMerge = true
                }) {
                    Label("PDF合併", systemImage: "doc.fill.badge.plus")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .navigationTitle("NekoPDFKit")
            .sheet(isPresented: $showingPDFPreview) {
                Group {
                    if isGenerating {
                        ProgressView("Generating PDF...")
                    } else if let data = pdfData {
                        PDFPreviewView(pdfData: data)
                            .onAppear {
                                print("PDFPreviewView appeared with data size: \(data.count) bytes")
                            }
                            .onDisappear {
                                print("PDFPreviewView disappeared")
                            }
                    } else if let error = pdfState.error {
                        Text("Error: \(error.localizedDescription)")
                    } else {
                        Text("No PDF data available")
                            .onAppear {
                                print("No PDF data available")
                            }
                    }
                }
            }
            .sheet(isPresented: $showingPDFMerge) {
                PDFMergeView()
            }
        }
    }
    
    private func generateAndShowPDF() {
        isGenerating = true
        
        // 創建 PDF 文檔
        let pdfDocument = PDFDocument()
        
        // 遍歷所有圖片
        for (index, image) in selectedImages.enumerated() {
            print("Processing image \(index + 1) of \(selectedImages.count)")
            
            // 創建 PDF 頁面
            if let page = PDFPage(image: image) {
                pdfDocument.insert(page, at: index)
            }
        }
        
        // 生成 PDF 數據
        if let data = pdfDocument.dataRepresentation() {
            pdfData = data
            showingPDFPreview = true
        }
        
        isGenerating = false
    }
}

#Preview {
    ContentView()
}
