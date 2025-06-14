//
//  ContentView.swift
//  NekoPDFKit
//
//  Created by 千葉牧人 on 2025/6/14.
//

import SwiftUI
import PhotosUI

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
    @StateObject private var pdfState = PDFState()
    
    var body: some View {
        NavigationStack {
            VStack {
                if selectedImages.isEmpty {
                    ContentUnavailableView {
                        Label("沒有圖片", systemImage: "photo.on.rectangle")
                    } description: {
                        Text("點擊下方按鈕選擇圖片")
                    }
                } else {
                    PreviewGridView(images: $selectedImages)
                }
                
                HStack(spacing: 20) {
                    PhotosPicker(selection: $selectedItems,
                               maxSelectionCount: 0,
                               matching: .images) {
                        Label("選擇圖片", systemImage: "photo.on.rectangle")
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
                        .disabled(pdfState.isGenerating)
                    }
                }
                .padding()
            }
            .navigationTitle("NekoPDFKit")
            .sheet(isPresented: $showingPDFPreview) {
                Group {
                    if pdfState.isGenerating {
                        ProgressView("Generating PDF...")
                    } else if let data = pdfState.pdfData {
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
        }
    }
    
    private func generateAndShowPDF() {
        print("Starting PDF generation with \(selectedImages.count) images")
        showingPDFPreview = true
        pdfState.generatePDF(from: selectedImages)
    }
}

#Preview {
    ContentView()
}
