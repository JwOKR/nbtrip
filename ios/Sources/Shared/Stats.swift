import Foundation

struct Summary {
    var count: Int = 0
    var totalKm: Double = 0
    var totalSec: Double = 0
    var avgAll: Double = 0
    var avgMoving: Double = 0
    var peak: Double = 0
    var overPct: Double = 0

    var totalHours: Double { totalSec / 3600 }
}

enum Stats {
    static func summarize(_ data: TripData, limit: Double) -> Summary {
        var s = Summary()
        s.count = data.trips.count
        var wKm = 0.0, wMoving = 0.0
        var over = 0, total = 0
        for t in data.trips {
            s.totalKm += t.km
            s.totalSec += t.durS
            s.peak = max(s.peak, t.speedMax)
            if t.pts.isEmpty {
                // 无轨迹点时用服务端给的占比，按里程加权
                wKm += t.km; wMoving += t.movingMean * t.km
                s.overPct += t.overPct * t.km
            } else {
                for p in t.pts {
                    total += 1
                    if p.speed > limit { over += 1 }
                }
                if t.movingMean > 0 { wKm += t.km; wMoving += t.movingMean * t.km }
            }
        }
        s.avgAll = s.totalHours > 0 ? s.totalKm / s.totalHours : 0
        s.avgMoving = wKm > 0 ? wMoving / wKm : s.avgAll
        s.overPct = total > 0 ? Double(over) / Double(total) * 100 : (s.totalKm > 0 ? s.overPct / s.totalKm : 0)
        return s
    }

    /// 超速连续区间（用于图上染色），返回 (起点索引, 终点索引)
    static func overRanges(_ pts: [TripPoint], limit: Double) -> [(Int, Int)] {
        var out: [(Int, Int)] = []
        var startIdx: Int? = nil
        for (i, p) in pts.enumerated() {
            if p.speed > limit {
                if startIdx == nil { startIdx = i }
            } else if let s = startIdx {
                out.append((s, max(s, i - 1)))
                startIdx = nil
            }
        }
        if let s = startIdx { out.append((s, pts.count - 1)) }
        return out
    }

    /// 速度分布：0-10 / 10-15 / 15-20 / 20-25 / 25-30 / 30-40 / 40+
    static func histogram(_ pts: [TripPoint], limit: Double) -> [(label: String, count: Int, over: Bool)] {
        let edges: [(Double, Double, String)] = [
            (0, 10, "0-10"), (10, 15, "10-15"), (15, 20, "15-20"),
            (20, 25, "20-25"), (25, 30, "25-30"), (30, 40, "30-40"), (40, 999, "40+")
        ]
        return edges.map { lo, hi, label in
            let c = pts.filter { $0.speed >= lo && $0.speed < hi }.count
            return (label, c, lo >= limit)
        }
    }

    /// 按时间十等分
    static func segments(_ trip: Trip) -> [(t0: Double, t1: Double, km: Double, avg: Double, peak: Double)] {
        guard let last = trip.pts.last, last.t > 0 else { return [] }
        let n = 10, span = last.t / Double(n)
        var out: [(Double, Double, Double, Double, Double)] = []
        for i in 0..<n {
            let a = Double(i) * span, b = (i == n - 1) ? last.t : Double(i + 1) * span
            let seg = trip.pts.filter { $0.t >= a && $0.t <= b }
            if seg.isEmpty { out.append((a, b, 0, 0, 0)); continue }
            let km = (seg.last?.cumKm ?? 0) - (seg.first?.cumKm ?? 0)
            let sum = seg.reduce(0) { $0 + $1.speed }
            let peak = seg.reduce(0) { max($0, $1.speed) }
            out.append((a, b, max(0, km), sum / Double(seg.count), peak))
        }
        return out
    }
}
