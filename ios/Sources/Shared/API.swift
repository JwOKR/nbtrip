import Foundation

enum APIError: LocalizedError {
    case notConfigured
    case badURL
    case http(Int)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "还没填服务器地址"
        case .badURL: return "服务器地址格式不对"
        case .http(let c): return "HTTP \(c)"
        case .server(let s): return s
        }
    }
}

enum API {
    static func url(_ base: String, _ path: String) throws -> URL {
        var b = base.trimmingCharacters(in: .whitespacesAndNewlines)
        while b.hasSuffix("/") { b.removeLast() }
        guard !b.isEmpty, let u = URL(string: b + "/" + path) else { throw APIError.badURL }
        return u
    }

    static func request(_ base: String, _ path: String,
                        user: String, pass: String) throws -> URLRequest {
        var r = URLRequest(url: try url(base, path), cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        r.timeoutInterval = 30
        if !user.isEmpty {
            let token = Data("\(user):\(pass)".utf8).base64EncodedString()
            r.setValue("Basic \(token)", forHTTPHeaderField: "Authorization")
        }
        return r
    }

    /// 拉 data.json（成功则写入缓存）
    static func fetchData(base: String, user: String, pass: String) async throws -> TripData {
        if base.isEmpty { throw APIError.notConfigured }
        let (data, resp) = try await URLSession.shared.data(for: try request(base, Config.dataPath, user: user, pass: pass))
        if let http = resp as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.http(http.statusCode)
        }
        let decoded = try JSONDecoder().decode(TripData.self, from: data)
        Store.saveCache(decoded)
        return decoded
    }

    /// 触发 NAS 拉取：POST/GET api/refresh?key=xxx
    static func triggerRefresh(base: String, key: String, user: String, pass: String) async throws {
        if base.isEmpty { throw APIError.notConfigured }
        var r = try request(base, Config.refreshPath, user: user, pass: pass)
        r.url = URL(string: r.url!.absoluteString + "?key=" +
                    (key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""))
        let (data, resp) = try await URLSession.shared.data(for: r)
        if let http = resp as? HTTPURLResponse, http.statusCode == 403 {
            throw APIError.server("密钥错误（REFRESH_KEY 不对）")
        }
        if let http = resp as? HTTPURLResponse, http.statusCode == 503 {
            throw APIError.server("服务端没配 REFRESH_KEY，远程更新已禁用")
        }
        if let http = resp as? HTTPURLResponse, http.statusCode == 409 {
            return // 已有任务在跑，直接进入轮询
        }
        if let http = resp as? HTTPURLResponse, !(200..<300).contains(http.statusCode), http.statusCode != 202 {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw APIError.server("HTTP \(http.statusCode) \(msg.prefix(120))")
        }
    }

    static func status(base: String, user: String, pass: String) async throws -> RefreshStatus {
        let (data, resp) = try await URLSession.shared.data(for: try request(base, Config.statusPath, user: user, pass: pass))
        if let http = resp as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.http(http.statusCode)
        }
        return try JSONDecoder().decode(RefreshStatus.self, from: data)
    }
}
