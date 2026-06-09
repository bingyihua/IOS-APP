import SwiftUI

struct ContentView: View {
    @EnvironmentObject var proxyManager: ProxyManager
    @State private var showingAddSheet = false
    @State private var showingScanner = false
    @State private var showingManualInput = false
    @State private var selectedConfigId: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Status Card
                    statusCard
                    
                    Spacer().frame(height: 20)
                    
                    // Connection Button
                    connectionButton
                    
                    Spacer().frame(height: 30)
                    
                    // Config List
                    configListSection
                    
                    Spacer().frame(height: 20)
                    
                    // Action Buttons
                    actionButtons
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationTitle("VlessBox")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { showingAddSheet = true } label: {
                            Label("手动添加", systemImage: "plus")
                        }
                        Button { showingScanner = true } label: {
                            Label("扫码添加", systemImage: "qrcode")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: ) {
                ManualInputView()
            }
            .sheet(isPresented: ) {
                QRScannerView()
            }
        }
    }
    
    // MARK: - Status Card
    private var statusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: proxyManager.status.icon)
                    .font(.title)
                    .foregroundStyle(proxyManager.status.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(proxyManager.status.description)
                        .font(.headline)
                    
                    if let config = proxyManager.currentConfig {
                        Text(config.name.isEmpty ? config.server : config.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Traffic stats when connected
            if proxyManager.status == .connected {
                HStack(spacing: 20) {
                    Text("↑ \(formatBytes(proxyManager.uploadBytes))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("↓ \(formatBytes(proxyManager.downloadBytes))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
    
    // MARK: - Connection Button
    private var connectionButton: some View {
        Button {
            proxyManager.toggleConnection()
        } label: {
            HStack {
                Image(systemName: proxyManager.isProxyActive ? "xmark.circle.fill" : "shield.lefthalf.filled")
                    .font(.title2)
                Text(proxyManager.isProxyActive ? "断开连接" : "连接")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(proxyManager.isProxyActive ? Color.red : Color.blue)
            .foregroundStyle(.white)
            .cornerRadius(12)
        }
        .disabled(proxyManager.currentConfig == nil && !proxyManager.isProxyActive)
    }
    
    // MARK: - Config List
    private var configListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("服务器配置")
                    .font(.headline)
                Text("(\(proxyManager.configs.count))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if proxyManager.configs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("暂无服务器配置")
                        .foregroundStyle(.secondary)
                    
                    Text("扫码或手动添加 Vmess 配置")
                        .font(.caption)
                        .foregroundStyle(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(proxyManager.configs) { config in
                    configCard(config)
                }
            }
        }
    }
    
    private func configCard(_ config: VmessConfig) -> some View {
        let isSelected = proxyManager.currentConfig?.id == config.id
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(config.name.isEmpty ? "未命名节点" : config.name)
                        .font(.subheadline.bold())
                    
                    HStack(spacing: 4) {
                        Text(config.server)
                        Text(":")
                        Text("\(config.port)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Protocol badges
                HStack(spacing: 4) {
                    if config.tls == "tls" || config.tls == "1.3" {
                        badge("TLS", .green)
                    }
                    if config.security == "ws" || config.security == "http" {
                        badge("WS", .blue)
                    }
                    if config.security == "grpc" {
                        badge("GRPC", .purple)
                    }
                }
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .onTapGesture {
                proxyManager.currentConfig = config
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(12)
        .onDelete(perform: deleteConfig)
    }
    
    private func badge(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .cornerRadius(4)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button { showingScanner = true } label: {
                VStack(spacing: 6) {
                    Image(systemName: "qrcode")
                        .font(.title2)
                    Text("扫码")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
            }
            
            Button { showingManualInput = true } label: {
                VStack(spacing: 6) {
                    Image(systemName: "pencil.and.list.clipboard")
                        .font(.title2)
                    Text("粘贴")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
            }
            
            Button {
                // Export current config
                if let config = proxyManager.currentConfig {
                    shareConfig(config)
                }
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                    Text("分享")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
            }
            .disabled(proxyManager.currentConfig == nil)
        }
    }
    
    // MARK: - Helpers
    private func deleteConfig(at offsets: IndexSet) {
        proxyManager.removeConfig(at: offsets)
    }
    
    private func shareConfig(_ config: VmessConfig) {
        let activityVC = UIActivityViewController(
            activityItems: [config.url],
            applicationActivities: nil
        )
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let forms = ["B", "KB", "MB", "GB", "TB"]
        var size = Double(bytes)
        var i = 0
        while size >= 1024 && i < forms.count - 1 {
            size /= 1024
            i += 1
        }
        return String(format: "%.1f%@", size, forms[i])
    }
}
