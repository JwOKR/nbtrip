import SwiftUI
import UIKit

struct TripDetailView: View {
    @EnvironmentObject var model: AppModel
    let trip: Trip

    private var limit: Double { model.limit }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                kpis
                if !trip.pts.isEmpty {
                    section("速度曲线") { SpeedChart(pts: trip.pts, limit: limit) }
                    section("速度分布") { SpeedHistogram(pts: trip.pts, limit: limit) }
                    section("轨迹") {
                        TrackCanvas(pts: trip.pts, limit: limit)
                        HStack(spacing: 14) {
                            legend(color: .nbOk, text: "起点")
                            legend(color: .nbRed, text: "终点 / 超速段")
                            Spacer()
                        }.font(.caption2).foregroundStyle(.secondary)
                    }
                    section("分段（按时间十等分）") { SegmentTable(trip: trip, limit: limit) }
                } else {
                    Text("这条行程没有轨迹点").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 24)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(fmtDate(trip.start))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(fmtDate(trip.start)).font(.title3.weight(.semibold))
                Text("\(fmtDur(trip.durS)) · \(trip.km.km) km")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(trip.speedMax.kmh)").font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(trip.speedMax > limit ? Color.nbRed : Color.primary)
                Text("峰值 km/h").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private var kpis: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                  spacing: 10) {
            KpiCard(trip.km.km, unit: "km", label: "里程")
            KpiCard(fmtDur(trip.durS), label: "时长")
            KpiCard(trip.movingMean.kmh, unit: "km/h", label: "行进均速")
            KpiCard(trip.speedMean.kmh, unit: "km/h", label: "全程均速")
            KpiCard(String(format: "%.0f%%", trip.overPct), label: "超速占比",
                    color: trip.overPct > 20 ? .nbRed : .primary)
            KpiCard("\(trip.points)", label: "轨迹点")
        }
    }

    private func section<V: View>(_ title: String, @ViewBuilder _ content: () -> V) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundStyle(.secondary).padding(.leading, 4)
            content()
        }
    }

    private func legend(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text)
        }
    }
}
