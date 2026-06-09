import Foundation
import Network

enum ProxyStatus: Codable {
    case disconnected
    case connecting
    case connected
    case error(String)
    
    var description: String {
        switch self {
        case .disconnected: return "未连接"
        case .connecting: return "连接中..."
        case .connected: return "已连接"
        case .error(let msg): return "错误: \(msg)"
        }
    }
    
    var icon: String {
        switch self {
        case .disconnected: return "circle"
        case .connecting: return "arrow.circlepath"
        case .connected: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle"
        }
    }
    
    var color: Color {
        switch self {
        case .disconnected: return .gray
        case .connecting: return .orange
        case .connected: return .green
        case .error: return .red
        }
    }
}

class ProxyManager: ObservableObject {
    static let shared = ProxyManager()
    
    @Published var status: ProxyStatus = .disconnected {
        didSet { print("[ProxyManager] status: \(status.description)") }
    }
    @Published var configs: [VmessConfig] = [] {
        didSet { saveConfigs() }
    }
    @Published var currentConfig: VmessConfig? {
        didSet { saveCurrentConfig() }
    }
    @Published var isProxyActive: Bool = false
    @Published var uploadBytes: UInt64 = 0
    @Published var downloadBytes: UInt64 = 0
    
    private let configsKey = "vmess_configs"
    private let currentConfigKey = "current_config_id"
    private let mihomoURL = URL(string: "http://127.0.0.1:9090")!
    private let controlSecret = "vlessbox123"
    private var session: URLSession?
    private var pingTimer: Timer?
    
    private init() {
        loadConfigs()
        session = URLSession(configuration: .default)
        // Check if proxy is already active
        checkProxyStatus()
    }
    
    // MARK: - Config Persistence
    func loadConfigs() {
        if let data = UserDefaults.standard.data(forKey: configsKey),
           let decoded = try? JSONDecoder().decode([VmessConfig].self, from: data) {
            configs = decoded
        }
        if let configId = UserDefaults.standard.string(forKey: currentConfigKey) {
            configs.first { .id == configId }
        }
    }
    
    func saveConfigs() {
        if let data = try? JSONEncoder().encode(configs) {
            UserDefaults.standard.set(data, forKey: configsKey)
        }
    }
    
    func saveCurrentConfig() {
        if let id = currentConfig?.id {
            UserDefaults.standard.set(id, forKey: currentConfigKey)
        }
    }
    
    // MARK: - Config Management
    func addConfig(_ config: VmessConfig) {
        configs.append(config)
    }
    
    func removeConfig(at offsets: IndexSet) {
        configs.remove(atOffsets: offsets)
    }
    
    func getConfigs() -> [VmessConfig] {
        return configs
    }
    
    // MARK: - Proxy Control
    func connect(_ config: VmessConfig) {
        guard config.isValid() else {
            status = .error("配置无效")
            return
        }
        
        currentConfig = config
        status = .connecting
        applyClashConfig { [weak self] success in
            guard let self = self else { return }
            if success {
                self.setProxyRule()
                self.startPing()
            } else {
                self.status = .error("启动代理失败，请确保已安装 Clash Meta")
            }
        }
    }
    
    func disconnect() {
        stopPing()
        clearProxy()
        status = .disconnected
        currentConfig = nil
    }
    
    func toggleConnection() {
        if isProxyActive {
            disconnect()
        } else if let config = currentConfig {
            connect(config)
        }
    }
    
    // MARK: - Clash Meta API
    private func applyClashConfig(completion: @escaping (Bool) -> Void) {
        guard let config = currentConfig else {
            completion(false)
            return
        }
        
        let yamlContent = generateFullYAML(config)
        
        // Write config to local file
        let fileURL = getLocalConfigURL()
        if let data = yamlContent.data(using: .utf8) {
            try? data.write(to: fileURL, options: .atomic)
        }
        
        // Try to reload via Clash API
        Task { @MainActor in
            let success = try await reloadMihomoConfig()
            if success {
                status = .connected
                isProxyActive = true
                completion(true)
            } else {
                // Fallback: try direct config update
                let success2 = try await updateConfigDirectly(yaml: yamlContent)
                if success2 {
                    status = .connected
                    isProxyActive = true
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    private func generateFullYAML(_ config: VmessConfig) -> String {
        return """
        mixed-port: 9090
        allow-lan: false
        mode: rule
        log-level: info
        ipv6: false
        dns:
          enable: true
          listen: 0.0.0.0:1053
          enhanced-mode: redir-host
          nameserver:
            - https://dns.alidns.com/dns-query
            - https://doh.pub/dns-query
        proxies:
        \(config.toClashYAML())
        proxy-groups:
          - name: PROXY
            type: select
            proxies:
              - 默认
          - name: 默认
            type: url-test
            proxies:
              - VMess节点
            url: http://www.gstatic.com/generate_204
            interval: 300
          - name: VMess节点
            type: fallback
            proxies:
              - DIRECT
        rules:
          - RULE-SET,lan,DIRECT
          - DOMAIN-SUFFIX,cn,DIRECT
          - RULE-SET,cn,DIRECT
          - GEOIP,CN,DIRECT
          - MATCH,PROXY
        """
    }
    
    private func getLocalConfigURL() -> URL {
        let dir = FileManager.default.temporaryDirectory
        return dir.appendingPathComponent("clash-config.yaml")
    }
    
    private func reloadMihomoConfig() async throws -> Bool {
        let fileURL = getLocalConfigURL()
        guard let formData = await createMultipartFormData(fileURL: fileURL) else {
            return false
        }
        
        return await withCheckedContinuation { continuation in
            var request = URLRequest(url: mihomoURL.appendingPathComponent("/configs?overwrite=true"))
            request.httpMethod = "PUT"
            request.setValue("Bearer \(controlSecret)", forHTTPHeaderField: "Authorization")
            
            let task = session?.uploadTask(with: request, from: formData) { data, response, error in
                if error == nil, let httpResponse = response as? HTTPURLResponse,
                   (200...299).contains(httpResponse.statusCode) {
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(returning: false)
                }
            }
            task?.resume()
        }
    }
    
    private func updateConfigDirectly(yaml: String) async -> Bool {
        var request = URLRequest(url: mihomoURL.appendingPathComponent("/configs?overwrite=true"))
        request.httpMethod = "PATCH"
        request.setValue("application/yaml", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(controlSecret)", forHTTPHeaderField: "Authorization")
        request.httpBody = yaml.data(using: .utf8)
        
        return await withCheckedContinuation { continuation in
            let task = session?.dataTask(with: request) { data, response, error in
                let success = error == nil && (response as? HTTPURLResponse)?.statusCode == 204
                continuation.resume(returning: success)
            }
            task?.resume()
        }
    }
    
    private func createMultipartFormData(fileURL: URL) async -> Data? {
        var body = Data()
        
        // filename part
        body.append("--\\\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"config.yaml\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        
        // file content
        if let fileData = try? Data(contentsOf: fileURL) {
            body.append(fileData)
        } else { return nil }
        
        // closing boundary
        body.append("\r\n---\\\r\n".data(using: .utf8)!)
        
        return body
    }
    
    private func setProxyRule() {
        // Set system proxy via NetworkExtension (NEPacketTunnelProvider)
        // For now, we configure Clash Meta to run in TUN mode
        Task {
            // Enable TUN mode via Clash API
            var request = URLRequest(url: mihomoURL.appendingPathComponent("/proxies/PROXY"))
            request.httpMethod = "PUT"
            
            let task = session?.dataTask(with: request) { _, _, _ in
                // Proxy set to PROXY group
            }
            task?.resume()
        }
    }
    
    private func clearProxy() {
        Task {
            var request = URLRequest(url: mihomoURL.appendingPathComponent("/proxies/PROXY"))
            request.httpMethod = "DELETE"
            session?.dataTask(with: request).resume()
        }
    }
    
    private func startPing() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkProxyStatus()
        }
    }
    
    private func stopPing() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func checkProxyStatus() {
        Task {
            let healthy = await checkMihomoHealth()
            if !healthy {
                await MainActor.run {
                    if isProxyActive {
                        self.status = .error("连接断开")
                        self.isProxyActive = false
                    }
                }
            }
        }
    }
    
    private func checkMihomoHealth() async -> Bool {
        var request = URLRequest(url: mihomoURL.appendingPathComponent("/healthcheck"))
        request.httpMethod = "GET"
        
        return await withCheckedContinuation { continuation in
            let task = session?.dataTask(with: request) { data, response, error in
                continuation.resume(returning: error == nil)
            }
            task?.resume()
        }
    }
}

// MARK: - Data helpers
extension NSMutableData {
    func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data, length: data.count)
        }
    }
}
