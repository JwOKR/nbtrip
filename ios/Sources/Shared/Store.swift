import Foundation

/// 配置 + 缓存读写。
/// App Group 不可用时（免费账号自签常见）自动回退到各自的沙盒，不会崩。
enum Store {
    static var defaults: UserDefaults {
        UserDefaults(suiteName: Config.appGroupID) ?? .standard
    }

    static var cacheURL: URL {
        if let u = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Config.appGroupID) {
            return u.appendingPathComponent("data.json")
        }
        let doc = FileManager.default.urls(for: .documentDirectory,
                                           in: .userDomainMask).first
        return (doc ?? URL(fileURLWithPath: NSTemporaryDirectory()))
            .appendingPathComponent("data.json")
    }

    // MARK: - 配置

    // 写入同时落到 App Group 与 standard：免费账号下 App Group 可能失效，
    // 两边都写可保证 App 自己的设置不丢。
    private static func str(_ k: String) -> String {
        defaults.string(forKey: k) ?? UserDefaults.standard.string(forKey: k) ?? ""
    }
    private static func put(_ k: String, _ v: String) {
        defaults.set(v, forKey: k)
        UserDefaults.standard.set(v, forKey: k)
    }

    static var serverURL: String {
        get { let v = str("nb.serverURL"); return v.isEmpty ? Config.defaultServerURL : v }
        set { put("nb.serverURL", newValue) }
    }
    static var refreshKey: String {
        get { let v = str("nb.key"); return v.isEmpty ? Config.defaultRefreshKey : v }
        set { put("nb.key", newValue) }
    }
    static var basicUser: String {
        get { let v = str("nb.user"); return v.isEmpty ? Config.defaultBasicUser : v }
        set { put("nb.user", newValue) }
    }
    static var basicPass: String {
        get { let v = str("nb.pass"); return v.isEmpty ? Config.defaultBasicPass : v }
        set { put("nb.pass", newValue) }
    }
    static var speedLimit: Double {
        get {
            let v = defaults.double(forKey: "nb.limit")
            let w = UserDefaults.standard.double(forKey: "nb.limit")
            let x = v > 0 ? v : w
            return x > 0 ? x : Config.speedLimitDefault
        }
        set {
            defaults.set(newValue, forKey: "nb.limit")
            UserDefaults.standard.set(newValue, forKey: "nb.limit")
        }
    }

    static var configured: Bool { !serverURL.isEmpty }

    // MARK: - 缓存

    static func saveCache(_ data: TripData) {
        if let d = try? JSONEncoder().encode(data) {
            try? d.write(to: cacheURL, options: .atomic)
        }
    }

    static func loadCache() -> TripData? {
        guard let d = try? Data(contentsOf: cacheURL) else { return nil }
        return try? JSONDecoder().decode(TripData.self, from: d)
    }
}
