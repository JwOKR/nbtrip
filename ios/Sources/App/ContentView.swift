import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var model: AppModel
    @State private var showSettings = false
    @State private var showImporter = false

    var body: some View {
        NavigationStack {
            Group {
                if model.data == nil && model.isLoading {
                    ProgressView("正在加载行程…").frame(maxHeight: .infinity)
                } else if let d = model.data, !d.trips.isEmpty {
                    tripList(d)
                } else {
                    emptyState
                }
            }
            .navigationTitle("行程速度")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await model.remoteRefresh() }
                    } label: {
                        if model.isRefreshing {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                    .disabled(model.isRefreshing)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    if let raw = try? Data(contentsOf: url),
                       let td = try? JSONDecoder().decode(TripData.self, from: raw) {
                        Store.saveCache(td)
                        model.data = td
                        model.error = nil
                    } else {
                        model.error = "这个文件不是有效的 data.json"
                    }
                case .failure(let e):
                    model.error = e.localizedDescription
                }
            }
            .refreshable { await model.load() }
            .safeAreaInset(edge: .bottom) { statusBar }
        }
    }

    // MARK: - 列表

    private func tripList(_ d: TripData) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                header(d)
                overview
                HStack {
                    Text("行程").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("共 \(d.trips.count) 条").font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)

                LazyVStack(spacing: 10) {
                    ForEach(model.sortedTrips) { t in
                        NavigationLink(value: t.id) {
                            TripRow(trip: t, limit: model.limit)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 20)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationDestination(for: String.self) { id in
            if let t = model.data?.trips.first(where: { $0.id == id }) {
                TripDetailView(trip: t)
            }
        }
    }

    private func header(_ d: TripData) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(d.vehicle ?? "九号").font(.headline)
                if let sn = d.sn, !sn.isEmpty {
                    Text("SN \(sn)").font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let f = d.fetchedAt {
                Text(f.replacingOccurrences(of: "T", with: " "))
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private var overview: some View {
        let s = model.summary
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                         spacing: 10) {
            KpiCard(s.totalKm.km, unit: "km", label: "总里程")
            KpiCard(fmtDur(s.totalSec), label: "总时长")
            KpiCard(s.avgMoving.kmh, unit: "km/h", label: "行进均速")
            KpiCard(s.peak.kmh, unit: "km/h", label: "峰值", color: .nbRed)
            KpiCard(String(format: "%.0f%%", s.overPct), label: "超速占比",
                    color: s.overPct > 20 ? .nbRed : .primary)
            KpiCard("\(s.count)", label: "行程数")
        }
    }

    private var emptyState: some View {
        let configured = !Store.serverURL.isEmpty
        return VStack(spacing: 14) {
            Image(systemName: "bolt.horizontal.fill")
                .font(.system(size: 42)).foregroundStyle(.nbAccent.opacity(0.7))
            Text(configured ? (model.error ?? "还没拉到数据")
                            : "在设置里填 NAS 看板地址，或直接导入 data.json")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("去设置服务器地址") { showSettings = true }
                .buttonStyle(.borderedProminent)
            Button("导入 data.json") { showImporter = true }
                .buttonStyle(.bordered)
        }
        .padding(40)
        .frame(maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }

    private var statusBar: some View {
        Group {
            if let n = model.refreshNote {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text(n).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(.regularMaterial)
            } else if let e = model.error {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.nbAmber)
                    Text(e).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(.regularMaterial)
            }
        }
    }
}

// MARK: - 行程行

struct TripRow: View {
    let trip: Trip
    let limit: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(fmtDate(trip.start)).font(.subheadline.weight(.medium))
                Spacer()
                Text("\(trip.km.km) km")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
            }
            HStack(spacing: 12) {
                stat("时长", fmtDur(trip.durS))
                stat("均速", trip.movingMean.kmh)
                stat("峰值", trip.speedMax.kmh, color: trip.speedMax > limit ? .nbRed : .primary)
                Spacer()
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule().fill(Color.nbRed)
                        .frame(width: max(0, g.size.width * CGFloat(min(1, trip.overPct / 100))))
                }
            }
            .frame(height: 5)
        }
        .padding(13)
        .background(Color(UIColor.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    private func stat(_ k: String, _ v: String, color: Color = .primary) -> some View {
        HStack(spacing: 3) {
            Text(k).font(.caption2).foregroundStyle(.secondary)
            Text(v).font(.caption.monospacedDigit()).foregroundStyle(color)
        }
    }
}
