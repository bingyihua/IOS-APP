import SwiftUI

struct ManualInputView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var proxyManager: ProxyManager
    @State private var inputText: String = ""
    @State private var nodeName: String = ""
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Input area
                    TextEditor(text: )
                        .frame(minHeight: 200)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    // Node name (optional)
                    TextField("节点名称（可选）", text: )
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    // Parse button
                    Button {
                        parseAndAdd()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("添加配置")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    
                    // Error message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Supported formats info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("支持的格式：")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        
                        Text("1. vmess:// 或 vless:// 链接")
                            .font(.caption)
                        Text("2. Clash / Clash.Meta YAML 配置")
                            .font(.caption)
                        Text("3. Base64 编码的 Clash 配置")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("手动添加")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") { parseAndAdd() }
                }
            }
        }
    }
    
    private func parseAndAdd() {
        errorMessage = ""
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            errorMessage = "请输入配置信息"
            return
        }
        
        let configs = QRCodeParser.parseAny(trimmed)
        
        if configs.isEmpty {
            errorMessage = "未能解析出有效配置，请检查格式"
            return
        }
        
        for config in configs {
            if !nodeName.isEmpty && configs.count == 1 {
                config.name = nodeName
            } else if config.name.isEmpty {
                config.name = "节点 \(proxyManager.configs.count + 1)"
            }
            proxyManager.addConfig(config)
        }
        
        if configs.count == 1 {
            proxyManager.currentConfig = configs[0]
        }
        
        dismiss()
    }
}
