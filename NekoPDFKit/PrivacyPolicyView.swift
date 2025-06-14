import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Group {
                    Text("隱私政策")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("最後更新日期：2024年3月")
                        .foregroundColor(.secondary)
                    
                    Text("NekoPDFKit 重視您的隱私。本隱私政策說明我們如何處理您的數據。")
                }
                
                Group {
                    Text("數據收集")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("NekoPDFKit 不會收集或存儲您的任何個人數據。所有文件處理都在您的設備上本地完成。")
                }
                
                Group {
                    Text("照片訪問")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("NekoPDFKit 需要訪問您的照片庫才能選擇圖片進行 PDF 轉換。我們只會訪問您明確選擇的圖片，並且不會將這些圖片上傳到任何服務器。")
                }
                
                Group {
                    Text("文件處理")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("所有 PDF 文件都在您的設備上本地生成。我們不會將您的文件上傳到任何服務器或與第三方共享。")
                }
                
                Group {
                    Text("數據存儲")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("NekoPDFKit 不會在您的設備之外存儲任何數據。所有處理的文件都存儲在您的設備上，您可以隨時刪除。")
                }
                
                Group {
                    Text("第三方服務")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("NekoPDFKit 不使用任何第三方分析或廣告服務。")
                }
                
                Group {
                    Text("兒童隱私")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("NekoPDFKit 不針對 13 歲以下的兒童。我們不會故意收集兒童的個人信息。")
                }
                
                Group {
                    Text("隱私政策更新")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("我們可能會不時更新本隱私政策。任何更改都將在此頁面上發布。")
                }
                
                Group {
                    Text("聯絡我們")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("如果您對本隱私政策有任何疑問，請通過以下方式聯絡我們：")
                    
                    Link("makiakatsu@gmail.com", destination: URL(string: "mailto:makiakatsu@gmail.com")!)
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("隱私政策")
    }
}

#Preview {
    NavigationView {
        PrivacyPolicyView()
    }
} 