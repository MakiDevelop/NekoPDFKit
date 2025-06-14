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

struct ImageGridView: View {
    let images: [UIImage]
    let onDelete: (Int) -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 16)
            ], spacing: 16) {
                ForEach(0..<images.count, id: \.self) { index in
                    Image(uiImage: images[index])
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation {
                                    onDelete(index)
                                }
                            } label: {
                                Label("刪除", systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
        }
    }
}

struct ActionButtonsView: View {
    @Binding var selectedItems: [PhotosPickerItem]
    let hasImages: Bool
    let isGenerating: Bool
    let onGenerate: () -> Void
    let onMerge: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                PhotosPicker(selection: $selectedItems,
                           maxSelectionCount: 0,
                           matching: .images) {
                    Label("選擇圖片", systemImage: "photo.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                }
                
                if hasImages {
                    Button(action: onGenerate) {
                        Label("預覽PDF", systemImage: "doc.fill")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 2)
                    }
                    .disabled(isGenerating)
                }
            }
            
            Button(action: onMerge) {
                Label("PDF合併", systemImage: "doc.fill.badge.plus")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
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
        TabView {
            NavigationStack {
                VStack(spacing: 0) {
                    if selectedImages.isEmpty {
                        ContentUnavailableView {
                            Label("沒有圖片", systemImage: "photo.fill")
                        } description: {
                            Text("點擊下方按鈕選擇圖片")
                        }
                        .padding(.bottom, 20)
                    } else {
                        ImageGridView(images: selectedImages) { index in
                            selectedImages.remove(at: index)
                        }
                    }
                    
                    ActionButtonsView(
                        selectedItems: $selectedItems,
                        hasImages: !selectedImages.isEmpty,
                        isGenerating: isGenerating,
                        onGenerate: generateAndShowPDF,
                        onMerge: { showingPDFMerge = true }
                    )
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
                .onChange(of: selectedItems) { oldValue, newItems in
                    Task {
                        var images: [UIImage] = []
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                images.append(image)
                            }
                        }
                        withAnimation {
                            selectedImages.append(contentsOf: images)
                        }
                        selectedItems.removeAll()
                    }
                }
            }
            .tabItem {
                Label("首頁", systemImage: "house.fill")
            }
            
            NavigationStack {
                AboutView()
            }
            .tabItem {
                Label("關於", systemImage: "info.circle.fill")
            }
        }
    }
    
    private func generateAndShowPDF() {
        isGenerating = true
        
        let pdfDocument = PDFDocument()
        
        for (index, image) in selectedImages.enumerated() {
            print("Processing image \(index + 1) of \(selectedImages.count)")
            
            if let page = PDFPage(image: image) {
                pdfDocument.insert(page, at: index)
            }
        }
        
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
