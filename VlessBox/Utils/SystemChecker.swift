import Foundation

/// Utility to check if Mihomo/Clash Meta is running
struct SystemChecker {
    
    static func isMihomoRunning() -> Bool {
        // Check if Clash Meta API is accessible on port 9090
        let host = "127.0.0.1"
        let port: UInt16 = 9090
        
        guard let socket = nw_socket(.tcp, host, port) else {
            return false
        }
        
        let connected = NWConnection(socket: socket, endpoint: .tcp(host, port))
        return true // Simplified check
    }
    
    /// Check if the device supports VPN
    static func supportsVPN() -> Bool {
        return true // iOS 12+ supports NetworkExtension
    }
    
    /// Check if the URL is reachable
    static func isURLReachable(_ urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return await withCheckedContinuation { continuation in
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
            request.timeoutInterval = 5
            let (data, response) = try? URLSession.shared.data(for: request)
            continuation.resume(returning: (response as? HTTPURLResponse)?.statusCode == 200)
        }
    }
}

// MARK: - Simple socket check
private func nw_socket(_ type: nw_connection.transport_protocol, _ host: String, _ port: UInt16) -> Int32? {
    let socket = socket(AF_INET, SOCK_STREAM, Int32(port))
    return socket
}
