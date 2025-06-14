import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Logo and Name
                VStack(spacing: 16) {
                    Image("NekoPDFKitBG")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 5)
                    
                    Text("NekoPDFKit")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("版本 1.0.0")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Features
                VStack(alignment: .leading, spacing: 20) {
                    Text("主要功能")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    FeatureRow(icon: "photo.fill", title: "圖片轉PDF", description: "輕鬆將多張圖片轉換為PDF文件")
                    FeatureRow(icon: "doc.stack.fill", title: "PDF合併", description: "將多個PDF文件合併為一個文件")
                    FeatureRow(icon: "square.and.arrow.up.fill", title: "分享功能", description: "一鍵分享生成的PDF文件")
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(radius: 2)
                
                // Contact
                VStack(alignment: .leading, spacing: 20) {
                    Text("聯絡我")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Link(destination: URL(string: "mailto:makiakatsu@gmail.com")!) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                            Text("makiakatsu@gmail.com")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Link(destination: URL(string: "https://twitter.com/nekopdfkit")!) {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                            Text("Twitter")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(radius: 2)
                
                // Privacy Policy
                VStack(alignment: .leading, spacing: 20) {
                    Text("隱私政策")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("NekoPDFKit 重視您的隱私。我們不會收集或存儲您的任何個人數據。所有文件處理都在本地完成。")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(radius: 2)
                
                Spacer()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("關於")
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationView {
        AboutView()
    }
} 
