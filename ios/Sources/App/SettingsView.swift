import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var serverURL = Store.serverURL
    @State private var refreshKey = Store.refreshKey
    @State private var user = Store.basicUser
    @State private var pass = Store.basicPass
    @State private var limit: Double = Store.speedLimit
    @State private var testing = false
    @State private var testResult: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://trip.551129.xyz", text: $serverURL)
                        .keyboardType(.URL).autocapitalization(.none)
                        .autocorrectionDisabled()
                } header: {
                    Text("服务器")
                } footer: {
                    Text("NAS 上看板的地址。内网用 http://<NAS IP>:8088，公网用 Cloudflare Tunnel 的 https 域名。")
                }

                Section("远程更新密钥") {
                    SecureField("REFRESH_KEY", text: $refreshKey)
                        .autocapitalization(.none).autocorrectionDisabled()
                }

                Section {
                    TextField("用户名（可选）", text: $user).autocapitalization(.none)
                    SecureField("密码（可选）", text: $pass)
                } header: {
                    Text("整站登录保护")
                } footer: {
                    Text("只有在 NAS 的 .env 里开了 SITE_USER / SITE_PASS 才需要填。")
                }

                Section("限速") {
                    HStack {
                        Text("\(Int(limit)) km/h").monospacedDigit()
                        Slider(value: $limit, in: 5...80, step: 1)
                    }
                    .onChange(of: limit) { v in model.updateLimit(v) }
                }

                Section {
                    Button {
                        testing = true; testResult = nil
                        Task {
                            do {
                                let d = try await API.fetchData(base: Store.serverURL,
                                                                user: Store.basicUser,
                                                                pass: Store.basicPass)
                                testResult = "连接成功：\(d.trips.count) 条行程"
                                await model.load()
                            } catch {
                                testResult = "失败：\(error.localizedDescription)"
                            }
                            testing = false
                        }
                    } label: {
                        HStack {
                            Text("测试连接并重新加载")
                            Spacer()
                            if testing { ProgressView().controlSize(.small) }
                        }
                    }
                    if let r = testResult {
                        Text(r).font(.caption)
                            .foregroundStyle(r.hasPrefix("失败") ? Color.nbRed : Color.nbOk)
                    }
                }

                Section {
                    Button("重新加载数据") { Task { await model.load() } }
                    Button("触发 NAS 立即更新") { Task { await model.remoteRefresh() } }
                }

                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(appVersion).foregroundStyle(.secondary)
                    }
                    Link("小组件使用说明", destination: URL(string: "https://support.apple.com/zh-cn/HT207122")!)
                } footer: {
                    Text("小组件：长按主屏幕 → 左上角 + → 搜索「行程速度」→ 添加。若小组件一直空白，说明免费账号下 App Group 不生效，需要在 Config.swift 里把 defaultServerURL 写成你的地址后重新编译。")
                }
            }
            .navigationTitle("设置")
            .onChange(of: serverURL) { Store.serverURL = $0 }
            .onChange(of: refreshKey) { Store.refreshKey = $0 }
            .onChange(of: user) { Store.basicUser = $0 }
            .onChange(of: pass) { Store.basicPass = $0 }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
