import SwiftUI
import UIKit

extension Color {
    static let nbAccent = Color(red: 0.15, green: 0.45, blue: 1.0)
    static let nbRed = Color(red: 0.88, green: 0.20, blue: 0.20)
    static let nbOk = Color(red: 0.05, green: 0.65, blue: 0.45)
    static let nbAmber = Color(red: 0.85, green: 0.55, blue: 0.10)
}

// 让 .foregroundStyle(.nbAccent) / .tint(.nbAccent) 这类 ShapeStyle 位置也能用自定义色
extension ShapeStyle where Self == Color {
    static var nbAccent: Color { Color.nbAccent }
    static var nbRed: Color { Color.nbRed }
    static var nbOk: Color { Color.nbOk }
    static var nbAmber: Color { Color.nbAmber }
}

extension Double {
    var kmh: String { String(format: "%.1f", self) }
    var km: String { String(format: "%.1f", self) }
}

func fmtDur(_ s: Double) -> String {
    let v = Int(max(0, s))
    let h = v / 3600, m = (v % 3600) / 60
    if h > 0 { return "\(h)h\(m)m" }
    if m > 0 { return "\(m)m" }
    return "\(v)s"
}

func fmtDate(_ t: Double) -> String {
    let d = Date(timeIntervalSince1970: t)
    let f = DateFormatter()
    f.dateFormat = "M/d HH:mm"
    return f.string(from: d)
}

struct KpiCard: View {
    let value: String
    let unit: String?
    let label: String
    let color: Color

    init(_ value: String, unit: String? = nil, label: String, color: Color = .primary) {
        self.value = value; self.unit = unit; self.label = label; self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                if let u = unit {
                    Text(u).font(.caption2).foregroundStyle(.secondary)
                }
            }
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12).padding(.horizontal, 13)
        .background(Color(UIColor.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}
