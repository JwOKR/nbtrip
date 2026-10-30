# NbTrip · 行程速度 iOS App（SwiftUI + 小组件）

九号电自行程速度看板的**原生 iOS 版**：SwiftUI 编写，带 WidgetKit 小组件，
数据来自 NAS 上的看板（`dashboard/mobile` 的 `server.py`）。

## 功能

- **总览**：总里程 / 总时长 / 行进均速 / 峰值 / 超速占比 / 行程数（原生大数字卡片）
- **行程列表**：日期、里程、时长、均速、峰值，超速占比进度条，下拉刷新
- **详情**：Swift Charts 速度曲线（限速虚线 + 超速区红色染色）、速度分布直方图、
  Canvas 自绘 GPS 轨迹（超速段红、起点绿终点红）、按时间十等分的分段表
- **小组件**（systemSmall / systemMedium）：
  - Small：最近行程的里程、时长、均速、峰值、超速占比
  - Medium：左侧累计统计 + 右侧最近行程迷你速度曲线
- **远程更新**：App 内一键触发 NAS 拉取（同 PWA 的「更新」按钮）
- 深色模式自适应、iOS 17+

## 目录

```
ios/NbTrip/
  project.yml               XcodeGen 工程定义（两个 target：App + Widget）
  Sources/Shared/           两个 target 共用：数据模型 / 配置 / 缓存 / API / 统计
  Sources/App/              App 界面
  Sources/Widget/           小组件
  Resources/                AppIcon（脚本生成）
  make_icon.py              重新生成图标
  build_ipa.sh              本地 Mac 一键出未签名 IPA
.github/workflows/ios.yml   云端 CI：推送即编译出未签名 IPA
```

## 没有 Mac？用 GitHub Actions 出 IPA

1. 新建一个 GitHub 仓库（**Public 仓库 macOS runner 免费不限时**；Private 有免费额度但 macOS 按 10 倍计费）
2. 把整个项目推上去（重点：`ios/` 目录 + `.github/workflows/ios.yml`）
3. （推荐）仓库 Settings → Secrets and variables → Actions：
   - Variable `NB_SERVER_URL` = `https://trip.551129.xyz`（写进去 App 和小组件开箱即用）
   - Secret `NB_REFRESH_KEY` = NAS `.env` 里的 REFRESH_KEY
   - 如果开了整站 Basic Auth：Variable `NB_BASIC_USER` + Secret `NB_BASIC_PASS`
4. Actions 页 → **Build iOS IPA** → Run workflow（或直接 push 触发）
5. 跑完后在 Artifacts 下载 `NbTrip-unsigned-ipa`，解压得到 `NbTrip-unsigned.ipa`

## 安装到 iPhone（免费 Apple ID，7 天有效）

1. 爱思助手 → 工具箱 → **IPA 签名** → 选 `NbTrip-unsigned.ipa` → 登录你的 Apple ID → 签名
2. 签名后的 IPA 用爱思安装到手机（或 AltStore：把 IPA 拖进 AltStore 安装，之后可自动续签）
3. 首次运行：设置 → 通用 → VPN与设备管理 → 信任你的开发者证书
4. 打开 App → 设置里填服务器地址（如果 CI 没注入）→ 测试连接

## 添加小组件

长按主屏幕空白处 → 左上角 **+** → 搜索「行程速度」→ 选尺寸添加。

数据逻辑：小组件优先读 App 更新的缓存（App Group 共享）；
拿不到缓存时**自己联网拉 `data.json`**（地址取自小组件内设置/编译期默认值），
所以即使 App Group 失效也能显示。

## ⚠️ 免费 Apple ID 的两个坑

| 坑 | 现象 | 解决 |
|---|---|---|
| 签名 7 天过期 | App 打不开 | AltStore 装可自动续签；或用爱思每 7 天重签 |
| App Group 不生效 | 小组件空白 | 在 `Sources/Shared/Config.swift` 把 `defaultServerURL` 写成你的地址重新编译（CI 注入变量即可）；App Group 生效时 App 内改的地址会自动同步给小组件 |

## 有 Mac 时本地编译

```bash
cd ios/NbTrip
sh build_ipa.sh        # 产出 NbTrip-unsigned.ipa
# 或者: xcodegen generate 后用 Xcode 打开 NbTrip.xcodeproj，连手机直接 Run
```

## 数据接口

| 接口 | 说明 |
|---|---|
| `GET  {base}/data.json` | 行程数据（同 PWA） |
| `GET  {base}/api/refresh?key=` | 触发 NAS 拉取 |
| `GET  {base}/api/status` | 更新进度 |

字段结构见 `dashboard/mobile/build.py` 的 slim() 输出。
