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
    @Binding var images: [UIImage]
    let onDelete: (Int) -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 16)
            ], spacing: 16) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                        .overlay(
                            Button(action: {
                                withAnimation {
                                    onDelete(index)
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .shadow(radius: 1)
                            }
                            .padding(4),
                            alignment: .topTrailing
                        )
                        .onDrag {
                            NSItemProvider(object: "\(index)" as NSString)
                        }
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .onDrop(of: [.text], delegate: ImageDropDelegate(images: $images))
    }
}

struct ImageDropDelegate: DropDelegate {
    @Binding var images: [UIImage]
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else { return false }
        
        itemProvider.loadObject(ofClass: String.self) { (string, error) in
            guard let fromIndexString = string as? String,
                  let fromIndex = Int(fromIndexString),
                  let toIndex = getDestinationIndex(info: info) else {
                return
            }
            
            if fromIndex != toIndex {
                DispatchQueue.main.async {
                    withAnimation {
                        let image = images.remove(at: fromIndex)
                        images.insert(image, at: toIndex)
                    }
                }
            }
        }
        return true
    }
    
    private func getDestinationIndex(info: DropInfo) -> Int? {
        let location = info.location
        let gridWidth: CGFloat = 100 + 16 // 圖片寬度 + 間距
        let gridHeight: CGFloat = 100 + 16 // 圖片高度 + 間距
        
        let column = Int(location.x / gridWidth)
        let row = Int(location.y / gridHeight)
        
        let totalColumns = Int(UIScreen.main.bounds.width / gridWidth)
        let index = row * totalColumns + column
        
        return index < images.count ? index : nil
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
                    HStack {
                        Image(systemName: "photo.fill")
                        Text("選擇圖片")
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                
                if hasImages {
                    Button(action: onGenerate) {
                        HStack {
                            Image(systemName: "doc.fill")
                            Text("預覽PDF")
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .disabled(isGenerating)
                }
            }
            
            Button(action: onMerge) {
                HStack {
                    Image(systemName: "doc.fill.badge.plus")
                    Text("PDF合併")
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: .orange.opacity(0.3), radius: 5, x: 0, y: 2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
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
                ZStack {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        if selectedImages.isEmpty {
                            VStack(spacing: 20) {
                                Image("NekoPDFKitBG")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(radius: 5)
                                
                                ContentUnavailableView {
                                    Label("沒有圖片", systemImage: "photo.fill")
                                } description: {
                                    Text("點擊下方按鈕選擇圖片")
                                }
                            }
                            .padding(.bottom, 20)
                        } else {
                            ImageGridView(
                                images: $selectedImages,
                                onDelete: { index in
                                    selectedImages.remove(at: index)
                                }
                            )
                        }
                        
                        ActionButtonsView(
                            selectedItems: $selectedItems,
                            hasImages: !selectedImages.isEmpty,
                            isGenerating: isGenerating,
                            onGenerate: generateAndShowPDF,
                            onMerge: { showingPDFMerge = true }
                        )
                    }
                }
                .navigationTitle("NekoPDFKit")
                .sheet(isPresented: $showingPDFPreview) {
                    Group {
                        if isGenerating {
                            ProgressView("Generating PDF...")
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(16)
                                .shadow(radius: 5)
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
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(16)
                                .shadow(radius: 5)
                        } else {
                            Text("No PDF data available")
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(16)
                                .shadow(radius: 5)
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
