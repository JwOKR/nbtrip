import SwiftUI
import WidgetKit

struct NbTripWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: NbTripEntry

    var body: some View {
        if let d = entry.data, let t = d.latest {
            switch family {
            case .systemMedium: medium(d, t)
            default: small(d, t)
            }
        } else {
            empty
        }
    }

    // MARK: - small

    private func small(_ d: TripData, _ t: Trip) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "bolt.horizontal.fill")
                    .font(.caption2).foregroundStyle(.nbAccent)
                Text("最近行程").font(.caption2).foregroundStyle(.secondary)
                Spacer()
            }
            Text(fmtDate(t.start)).font(.caption2).foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(t.km.km).font(.system(size: 30, weight: .semibold, design: .rounded))
                    .monospacedDigit().minimumScaleFactor(0.6)
                Text("km").font(.caption2).foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                mini("时长", fmtDur(t.durS))
                mini("均速", t.movingMean.kmh)
                mini("峰值", t.speedMax.kmh, color: t.speedMax > entry.limit ? .nbRed : .primary)
            }
            Spacer(minLength: 0)
            overBar(t.overPct)
        }
        .padding(14)
    }

    // MARK: - medium

    private func medium(_ d: TripData, _ t: Trip) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.horizontal.fill")
                        .font(.caption2).foregroundStyle(.nbAccent)
                    Text(d.vehicle ?? "行程速度").font(.caption2).foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(entry.summary.totalKm.km)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("累计 km").font(.caption2).foregroundStyle(.secondary)
                Spacer(minLength: 2)
                mini("均速", entry.summary.avgMoving.kmh)
                mini("峰值", entry.summary.peak.kmh,
                     color: entry.summary.peak > entry.limit ? .nbRed : .primary)
                mini("超速", String(format: "%.0f%%", entry.summary.overPct),
                     color: entry.summary.overPct > 20 ? .nbRed : .primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text(fmtDate(t.start)).font(.caption2).foregroundStyle(.secondary)
                MiniSpeedChart(pts: t.pts, limit: entry.limit)
                    .frame(height: 56)
                Text("\(t.km.km) km · \(fmtDur(t.durS))")
                    .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                overBar(t.overPct)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "bolt.horizontal.fill").foregroundStyle(.nbAccent)
                Text("行程速度").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(entry.note ?? "打开 App 加载一次数据")
                .font(.caption2).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
    }

    private func mini(_ k: String, _ v: String, color: Color = .primary) -> some View {
        HStack(spacing: 3) {
            Text(k).font(.caption2).foregroundStyle(.secondary)
            Text(v).font(.caption2.monospacedDigit()).foregroundStyle(color)
        }
    }

    private func overBar(_ pct: Double) -> some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.10))
                Capsule().fill(Color.nbRed)
                    .frame(width: max(0, g.size.width * CGFloat(min(1, pct / 100))))
            }
        }
        .frame(height: 4)
    }
}

/// 小组件里的迷你速度曲线（自绘，不依赖 Charts，渲染更快更稳）
struct MiniSpeedChart: View {
    let pts: [TripPoint]
    let limit: Double

    var body: some View {
        GeometryReader { g in
            let maxT = max(pts.last?.t ?? 1, 1)
            let maxV = max(pts.reduce(0) { max($0, $1.speed) }, limit * 1.2, 10)
            ZStack {
                // 限速线
                Path { p in
                    let y = g.size.height * (1 - CGFloat(limit / maxV))
                    p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: g.size.width, y: y))
                }
                .stroke(Color.nbRed.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

                Path { p in
                    for (i, pt) in pts.enumerated() {
                        let x = CGFloat(pt.t / maxT) * g.size.width
                        let y = g.size.height * (1 - CGFloat(pt.speed / maxV))
                        if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                        else { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(Color.nbAccent, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
    }
}
