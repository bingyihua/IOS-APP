import Foundation

struct VmessConfig: Identifiable, Codable, Hashable {
    var id: String { UUID().uuidString }
    var url: String
    var name: String = ""
    var server: String = ""
    var port: Int = 0
    var uuid: String = ""
    var alterId: Int = 0
    var security: String = "auto"
    var network: String = "tcp"
    var headerType: String = "none"
    var host: String = ""
    var path: String = ""
    var tls: String = ""
    var sni: String = ""
    var fingerprint: String = ""
    var wsPath: String = ""
    var wsHeaders: String = ""
    
    init(url: String) {
        self.url = url
        parseVmessURL(url)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKey.self)
        id = try container.decode(String.self, forKey: .id)
        url = try container.decode(String.self, forKey: .url)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        server = try container.decodeIfPresent(String.self, forKey: .server) ?? ""
        port = try container.decodeIfPresent(Int.self, forKey: .port) ?? 0
        uuid = try container.decodeIfPresent(String.self, forKey: .uuid) ?? ""
        alterId = try container.decodeIfPresent(Int.self, forKey: .alterId) ?? 0
        security = try container.decodeIfPresent(String.self, forKey: .security) ?? "auto"
        network = try container.decodeIfPresent(String.self, forKey: .network) ?? "tcp"
        headerType = try container.decodeIfPresent(String.self, forKey: .headerType) ?? "none"
        host = try container.decodeIfPresent(String.self, forKey: .host) ?? ""
        path = try container.decodeIfPresent(String.self, forKey: .path) ?? ""
        tls = try container.decodeIfPresent(String.self, forKey: .tls) ?? ""
        sni = try container.decodeIfPresent(String.self, forKey: .sni) ?? ""
        fingerprint = try container.decodeIfPresent(String.self, forKey: .fingerprint) ?? ""
        wsPath = try container.decodeIfPresent(String.self, forKey: .wsPath) ?? ""
        wsHeaders = try container.decodeIfPresent(String.self, forKey: .wsHeaders) ?? ""
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKey.self)
        try container.encode(id, forKey: .id)
        try container.encode(url, forKey: .url)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(server, forKey: .server)
        try container.encode(port, forKey: .port)
        try container.encodeIfPresent(uuid, forKey: .uuid)
        try container.encode(alterId, forKey: .alterId)
        try container.encodeIfPresent(security, forKey: .security)
        try container.encodeIfPresent(network, forKey: .network)
        try container.encodeIfPresent(headerType, forKey: .headerType)
        try container.encodeIfPresent(host, forKey: .host)
        try container.encodeIfPresent(path, forKey: .path)
        try container.encodeIfPresent(tls, forKey: .tls)
        try container.encodeIfPresent(sni, forKey: .sni)
        try container.encodeIfPresent(fingerprint, forKey: .fingerprint)
        try container.encodeIfPresent(wsPath, forKey: .wsPath)
        try container.encodeIfPresent(wsHeaders, forKey: .wsHeaders)
    }
    
    enum CodingKey: String, CodingKey {
        case id, url, name, server, port, uuid, alterId, security, network, headerType, host, path, tls, sni, fingerprint, wsPath, wsHeaders
    }
    
    mutating func parseVmessURL(_ urlString: String) {
        guard urlString.hasPrefix("vmess://"),
              let data = Data(base64Encoded: String(urlString.dropFirst(8))),
              let json = String(data: data, encoding: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data.utf8.data(using: .utf8) ?? Data()) as? [String: Any] else {
            return
        }
        
        server = dict["add"] as? String ?? ""
        port = dict["port"] as? Int ?? 0
        uuid = dict["id"] as? String ?? ""
        alterId = dict["aid"] as? Int ?? 0
        security = (dict["net"] as? String ?? "") == "" ? "auto" : (dict["net"] as? String ?? "tcp")
        network = dict["type"] as? String ?? "none"
        headerType = network
        host = dict["host"] as? String ?? ""
        path = dict["path"] as? String ?? ""
        wsPath = path
        tls = dict["tls"] as? String ?? ""
        sni = dict["sni"] as? String ?? ""
        fingerprint = dict["fp"] as? String ?? ""
        name = dict["ps"] as? String ?? ""
        
        if security == "auto" || security == "" {
            if let s = dict["scy"] as? String { security = s }
        }
        
        if server.isEmpty {
            // Fallback: try to parse as Clash format
            parseClashFormat(json)
        }
    }
    
    mutating func parseClashFormat(_ yamlString: String) {
        // Basic YAML parsing for Clash-style Vmess config
        let lines = yamlString.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("name:") {
                name = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("server:") {
                server = String(trimmed.dropFirst(7)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("port:") {
                port = Int(String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)) ?? 0
            } else if trimmed.hasPrefix("uuid:") {
                uuid = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("network:") {
                let net = String(trimmed.dropFirst(8)).trimmingCharacters(in: .whitespaces)
                if net == "ws" || net == "http" || net == "h2" { security = net }
                else if net == "tcp" { security = "tcp" }
                else { security = net }
            } else if trimmed.hasPrefix("ws-opts:") || trimmed.hasPrefix("http-opts:") {
                // Will parse nested later if needed
            } else if trimmed.hasPrefix("ws-path:") || trimmed.hasPrefix("path:") {
                path = String(trimmed.dropFirst(trimmed.firstIndex(of: ":")! + 1)).trimmingCharacters(in: .whitespaces)
                wsPath = path
            } else if trimmed.hasPrefix("tls:") {
                tls = "tls"
            } else if trimmed.hasPrefix("servername:") {
                sni = String(trimmed.dropFirst(11)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("fp:") {
                fingerprint = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            }
        }
    }
    
    func toClashYAML() -> String {
        var yaml = ""
        yaml += "  - name: \"\((name.isEmpty) ? server : name)\"\n"
        yaml += "    type: vmess\n"
        yaml += "    server: \(server)\n"
        yaml += "    port: \(port)\n"
        yaml += "    uuid: \(uuid)\n"
        yaml += "    alterId: \(alterId)\n"
        yaml += "    cipher: \(security.isEmpty ? \"auto\" : security)\n"
        yaml += "    network: \(networkConfig())\n"
        
        if network == "ws" || network == "http" || network == "h2" {
            yaml += "    ws-opts:\n"
            if !wsPath.isEmpty {
                yaml += "      path: \"\(wsPath)\"\n"
            }
            if !host.isEmpty {
                yaml += "      headers:\n"
                yaml += "        Host: \"\(host)\"\n"
            }
        } else if network == "http" || network == "h2" {
            yaml += "    http-opts:\n"
            if !host.isEmpty {
                yaml += "      headers:\n"
                yaml += "        Host: \"\(host)\"\n"
            }
        }
        
        if tls == "tls" || tls == "1.3" || tls == "" {
            if tls == "1.3" {
                yaml += "    tls: true\n"
            } else if tls == "tls" || (!tls.isEmpty) {
                yaml += "    tls: true\n"
            }
            if !sni.isEmpty {
                yaml += "    servername: \"\(sni)\"\n"
            }
            if !fingerprint.isEmpty {
                yaml += "    udp: true\n"
                yaml += "    tfo: true\n"
            }
        } else {
            yaml += "    tls: false\n"
        }
        
        if !fingerprint.isEmpty {
            yaml += "    fp: \"\(fingerprint)\"\n"
        }
        
        yaml += "    tfo: true\n"
        yaml += "    mptcp: true\n"
        
        return yaml
    }
    
    private func networkConfig() -> String {
        switch security {
        case "ws", "http", "h2": return security
        case "quic": return "quic"
        case "grpc": return "grpc"
        default: return "raw"
        }
    }
    
    func isValid() -> Bool {
        return !server.isEmpty && port > 0 && !uuid.isEmpty
    }
}

// MARK: - Support types
extension Data {
    static func fromBase64URL(_ base64: String) -> Data? {
        var base64 = base64
        base64 = base64.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")
        let padding = base64.count % 4
        if padding > 0 { base64 += String(repeating: "=", count: 4 - padding) }
        return Data(base64Encoded: base64)
    }
}
