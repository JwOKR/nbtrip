import WidgetKit
import SwiftUI

@main
struct NbTripWidgetBundle: WidgetBundle {
    var body: some Widget {
        NbTripWidget()
    }
}

struct NbTripEntry: TimelineEntry {
    let date: Date
    let data: TripData?
    let summary: Summary
    let limit: Double
    let note: String?

    static var placeholder: NbTripEntry {
        NbTripEntry(date: Date(), data: nil, summary: Summary(), limit: 25, note: nil)
    }
}

struct NbTripProvider: TimelineProvider {
    func placeholder(in context: Context) -> NbTripEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (NbTripEntry) -> Void) {
        let d = Store.loadCache() ?? Self.fetchSync()
        completion(Self.entry(with: d))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NbTripEntry>) -> Void) {
        var d = Store.loadCache()
        var note: String? = nil
        if d == nil {
            d = Self.fetchSync()
            if d == nil { note = "未取到数据" }
        }
        let entry = Self.entry(with: d, note: note)
        let now = Date()
        // 每 30 分钟一个 entry，1 小时后重新请求
        var entries: [NbTripEntry] = []
        for i in 0..<12 {
            entries.append(NbTripEntry(date: now.addingTimeInterval(Double(i) * 1800),
                                       data: entry.data, summary: entry.summary,
                                       limit: entry.limit, note: entry.note))
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(3600))))
    }

    private static func entry(with d: TripData?, note: String? = nil) -> NbTripEntry {
        let limit = Store.speedLimit
        return NbTripEntry(date: Date(), data: d,
                           summary: d.map { Stats.summarize($0, limit: limit) } ?? Summary(),
                           limit: limit, note: note)
    }

    /// Timeline 里没法直接 await，用信号量同步等待（最多 12 秒）
    private static func fetchSync() -> TripData? {
        let base = Store.serverURL
        guard !base.isEmpty else { return nil }
        let sem = DispatchSemaphore(value: 0)
        var result: TripData?
        Task.detached {
            result = try? await API.fetchData(base: base, user: Store.basicUser, pass: Store.basicPass)
            sem.signal()
        }
        _ = sem.wait(timeout: .now() + 12)
        return result
    }
}

struct NbTripWidget: Widget {
    let kind = "NbTripWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NbTripProvider()) { entry in
            NbTripWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("行程速度")
        .description("显示最近行程的里程、均速与超速占比")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
