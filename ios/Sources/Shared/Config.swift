import Foundation

/// 全局配置。
///
/// ⚠️ 免费 Apple ID 自签时，App Group 权限可能不生效。
/// 因此下面 4 个「编译期默认值」是小组件的兜底数据源：
/// 直接把 NAS 地址写在这里，小组件即使拿不到 App Group 也能自己联网取数。
/// CI 会用 repository 变量自动替换 __NB_xxx__ 占位符。
enum Config {
    static let defaultServerURL = "__NB_SERVER_URL__"
    static let defaultRefreshKey = "__NB_REFRESH_KEY__"
    static let defaultBasicUser = "__NB_BASIC_USER__"
    static let defaultBasicPass = "__NB_BASIC_PASS__"

    static let appGroupID = "group.com.jia.nbtrip"
    static let speedLimitDefault: Double = 25
    static let dataPath = "data.json"
    static let refreshPath = "api/refresh"
    static let statusPath = "api/status"
}
