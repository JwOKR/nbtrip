import SwiftUI
import UIKit
import Charts

struct SpeedChart: View {
    let pts: [TripPoint]
    let limit: Double

    private var peak: Double { pts.reduce(0) { max($0, $1.speed) } }
    private var tMax: Double { pts.last?.t ?? 1 }

    var body: some View {
        let yMax = max(limit * 1.5, peak * 1.15, 20)
        Chart {
            ForEach(Array(Stats.overRanges(pts, limit: limit).enumerated()), id: \.offset) { _, r in
                if r.0 < pts.count, r.1 < pts.count {
                    RectangleMark(
                        xStart: .value("开始", pts[r.0].t),
                        xEnd: .value("结束", pts[r.1].t),
                        yStart: .value("底", 0),
                        yEnd: .value("顶", yMax)
                    )
                    .foregroundStyle(Color.nbRed.opacity(0.13))
                }
            }
            ForEach(Array(pts.enumerated()), id: \.offset) { _, p in
                AreaMark(x: .value("时间", p.t), y: .value("速度", p.speed))
                    .foregroundStyle(LinearGradient(
                        colors: [Color.nbAccent.opacity(0.30), Color.nbAccent.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("时间", p.t), y: .value("速度", p.speed))
                    .foregroundStyle(Color.nbAccent)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            RuleMark(y: .value("限速", limit))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(Color.nbRed)
                .annotation(position: .top, alignment: .leading) {
                    Text("限速 \(Int(limit))").font(.caption2).foregroundStyle(Color.nbRed)
                }
        }
        .chartYScale(domain: 0...yMax)
        .chartXScale(domain: 0...max(tMax, 1))
        .chartXAxis {
            AxisMarks(position: .bottom, values: .automatic(desiredCount: 4)) { v in
                AxisValueLabel {
                    if let s = v.as(Double.self) { Text("\(Int(s / 60))′").font(.caption2) }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { v in
                AxisValueLabel { if let s = v.as(Double.self) { Text("\(Int(s))").font(.caption2) } }
                AxisGridLine()
            }
        }
        .frame(height: 190)
    }
}

struct SpeedHistogram: View {
    let pts: [TripPoint]
    let limit: Double

    var body: some View {
        let data = Stats.histogram(pts, limit: limit)
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { _, d in
                BarMark(
                    x: .value("区间", d.label),
                    y: .value("点数", d.count)
                )
                .foregroundStyle(d.over ? Color.nbRed.opacity(0.85) : Color.nbAccent.opacity(0.75))
                .cornerRadius(3)
            }
        }
        .chartXAxis {
            AxisMarks { v in
                AxisValueLabel {
                    if let s = v.as(String.self) { Text(s).font(.caption2) }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { v in
                AxisValueLabel { if let s = v.as(Int.self) { Text("\(s)").font(.caption2) } }
                AxisGridLine()
            }
        }
        .frame(height: 150)
    }
}

struct TrackCanvas: View {
    let pts: [TripPoint]
    let limit: Double

    var body: some View {
        Canvas { ctx, size in
            guard pts.count > 1 else { return }
            let lats = pts.map(\.lat), lngs = pts.map(\.lng)
            guard let minLat = lats.min(), let maxLat = lats.max(),
                  let minLng = lngs.min(), let maxLng = lngs.max() else { return }
            let pad: CGFloat = 12
            let w = size.width - pad * 2, h = size.height - pad * 2
            let dLat = max(maxLat - minLat, 1e-6), dLng = max(maxLng - minLng, 1e-6)
            let scale = min(w / CGFloat(dLng), h / CGFloat(dLat))
            let offX = pad + (w - CGFloat(dLng) * scale) / 2
            let offY = pad + (h - CGFloat(dLat) * scale) / 2
            func pt(_ p: TripPoint) -> CGPoint {
                CGPoint(x: offX + CGFloat(p.lng - minLng) * scale,
                        y: size.height - offY - CGFloat(p.lat - minLat) * scale)
            }
            var path = Path()
            path.move(to: pt(pts[0]))
            for p in pts.dropFirst() { path.addLine(to: pt(p)) }
            ctx.stroke(path, with: .color(Color.nbAccent.opacity(0.85)),
                       style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

            // 超速段
            for r in Stats.overRanges(pts, limit: limit) where r.1 < pts.count {
                var over = Path()
                over.move(to: pt(pts[r.0]))
                for i in r.0...r.1 { over.addLine(to: pt(pts[i])) }
                ctx.stroke(over, with: .color(Color.nbRed),
                           style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }
            // 起终点
            let start = pt(pts[0]), end = pt(pts[pts.count - 1])
            for (c, color) in [(start, Color.nbOk), (end, Color.nbRed)] {
                let r = CGRect(x: c.x - 4, y: c.y - 4, width: 8, height: 8)
                ctx.fill(Path(ellipseIn: r), with: .color(color))
                ctx.stroke(Path(ellipseIn: r), with: .color(.white.opacity(0.9)), lineWidth: 1.5)
            }
        }
        .frame(height: 200)
        .background(Color(UIColor.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}

struct SegmentTable: View {
    let trip: Trip
    let limit: Double

    var body: some View {
        let segs = Stats.segments(trip)
        return VStack(spacing: 0) {
            row("时段", "距离", "均速", "峰值", header: true)
            Divider()
            ForEach(Array(segs.enumerated()), id: \.offset) { i, s in
                row("\(Int(s.t0 / 60))-\(Int(s.t1 / 60))′",
                    "\(s.km.km) km",
                    s.avg.kmh,
                    s.peak.kmh,
                    highlight: s.peak > limit)
                if i < segs.count - 1 { Divider().padding(.leading, 4) }
            }
        }
        .font(.caption.monospacedDigit())
        .padding(.vertical, 6)
        .background(Color(UIColor.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func row(_ a: String, _ b: String, _ c: String, _ d: String,
                     header: Bool = false, highlight: Bool = false) -> some View {
        HStack {
            Text(a).frame(width: 62, alignment: .leading)
            Spacer()
            Text(b).frame(width: 62, alignment: .trailing)
            Text(c).frame(width: 48, alignment: .trailing)
            Text(d).frame(width: 48, alignment: .trailing)
                .foregroundStyle(highlight ? Color.nbRed : Color.primary)
        }
        .foregroundStyle(header ? Color.secondary : Color.primary)
        .padding(.horizontal, 12).padding(.vertical, 7)
    }
}
