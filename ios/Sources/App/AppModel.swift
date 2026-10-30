import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var data: TripData?
    @Published var limit: Double = Store.speedLimit
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var refreshNote: String?
    @Published var error: String?
    @Published var lastErrorAt: Date?

    var summary: Summary {
        guard let d = data else { return Summary() }
        return Stats.summarize(d, limit: limit)
    }

    var sortedTrips: [Trip] {
        (data?.trips ?? []).sorted { $0.start > $1.start }
    }

    func load(forceNetwork: Bool = true) async {
        if data == nil, let c = Store.loadCache() { data = c }
        guard forceNetwork else { return }
        isLoading = true; error = nil
        defer { isLoading = false }
        do {
            data = try await API.fetchData(base: Store.serverURL,
                                           user: Store.basicUser, pass: Store.basicPass)
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// 触发 NAS 远程更新：调 api/refresh，然后轮询 api/status，完成后拉回新数据
    func remoteRefresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        refreshNote = "已通知 NAS 拉取最新行程…"
        defer { isRefreshing = false }
        do {
            try await API.triggerRefresh(base: Store.serverURL, key: Store.refreshKey,
                                         user: Store.basicUser, pass: Store.basicPass)
            for i in 0..<150 {
                let s = try? await API.status(base: Store.serverURL,
                                              user: Store.basicUser, pass: Store.basicPass)
                if let s {
                    if s.running {
                        refreshNote = "NAS 正在拉取… \(s.elapsed ?? i * 2)s"
                    } else if s.ok == false {
                        refreshNote = nil
                        error = s.error?.isEmpty == false ? s.error : "更新失败，见 NAS 上的 refresh.log"
                        return
                    } else {
                        break
                    }
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
            refreshNote = "更新完成"
            data = try await API.fetchData(base: Store.serverURL,
                                           user: Store.basicUser, pass: Store.basicPass)
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            refreshNote = nil
        } catch {
            refreshNote = nil
            self.error = error.localizedDescription
        }
    }

    func updateLimit(_ v: Double) {
        limit = v
        Store.speedLimit = v
        objectWillChange.send()
    }
}
