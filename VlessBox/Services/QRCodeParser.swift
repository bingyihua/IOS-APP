import Foundation

struct QRCodeParser {
    /// Parse vmess:// URI scheme
    static func parse(_ urlString: String) -> VmessConfig? {
        guard urlString.hasPrefix("vmess://") else {
            return nil
        }
        
        let base64String = String(urlString.dropFirst(8))
        guard let data = Data(base64Encoded: base64String) else {
            return nil
        }
        
        guard let json = String(data: data, encoding: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        let config = VmessConfig(url: urlString)
        return config
    }
    
    /// Parse vless:// URI scheme
    static func parseVless(_ urlString: String) -> VmessConfig? {
        guard urlString.hasPrefix("vless://") else {
            return nil
        }
        
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        let uuid = url.userCredential ?? ""
        let host = url.host ?? ""
        let port = Int(url.port ?? 443) ?? 443
        
        let query = url.queryItems ?? []
        var config = VmessConfig(url: urlString)
        config.uuid = uuid
        config.server = host
        config.port = port
        config.name = url.fragment ?? ""
        
        for item in query {
            switch item.name {
            case "type":
                config.security = item.value ?? "tcp"
                config.network = item.value ?? "tcp"
            case "encryption":
                // vless requires encryption=scheme or none
            case "security":
                if item.value == "tls" || item.value == "xtls" {
                    config.tls = "tls"
                }
            case "sni":
                config.sni = item.value ?? ""
            case "path":
                config.path = item.value ?? ""
                config.wsPath = config.path
            case "host":
                config.host = item.value ?? ""
            case "fp":
                config.fingerprint = item.value ?? ""
            default:
                break
            }
        }
        
        return config
    }
    
    /// Parse any URL (vmess, vless, clash yaml, base64 clash)
    static func parseAny(_ text: String) -> [VmessConfig] {
        var configs: [VmessConfig] = []
        let lines = text.components(separatedBy: CharacterSet.newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("vmess://") {
                if let config = parse(trimmed), config.isValid() {
                    configs.append(config)
                }
            } else if trimmed.hasPrefix("vless://") {
                if let config = parseVless(trimmed), config.isValid() {
                    configs.append(config)
                }
            } else if trimmed.hasPrefix("{") || trimmed.hasPrefix("---") {
                // Clash YAML / JSON format
                let config = VmessConfig(url: trimmed)
                if config.isValid() {
                    configs.append(config)
                }
            }
        }
        
        return configs
    }
}
