# VlessBox iOS 构建与安装指南
# ============================

## 环境要求
- macOS 12+ (Monterey)
- Xcode 15+
- 一个 Apple ID（免费版即可）

## 方法一：直接在 Xcode 中运行（最快）

### 步骤 1：将项目复制到 Mac
将 E:\codex\VlessBox 整个文件夹复制到 Mac 上

### 步骤 2：用 Xcode 打开
`
cd /path/to/VlessBox
open VlessBox.xcodeproj
`

### 步骤 3：配置签名
1. 在 Xcode 左侧选择 VlessBox 项目
2. 选择 VlessBox Target
3. Signing and Capabilities 标签
4. 勾选 "Automatically manage signing"
5. 选择你的 Apple ID

### 步骤 4：连接 iPhone
通过 USB 连接 iPhone，在手机上信任你的电脑

### 步骤 5：运行
- 点击 Xcode 右上角的 ▶️ 按钮
- 或者 Command + R

## 方法二：构建 IPA 文件

### 方式 A：通过 Xcode Archive
1. Product -> Archive
2. Distribute App -> Development
3. 选择 Export
4. 用 AltStore 或 Sideloadly 安装到手机

### 方式 B：命令行构建
`ash
cd /path/to/VlessBox
xcodebuild -scheme VlessBox \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath build/VlessBox.xcarchive \
    archive

xcodebuild -exportArchive \
    -archivePath build/VlessBox.xcarchive \
    -exportPath build/VlessBox.ipa \
    -exportOptionsPlist export.plist
`

## 方法三：使用 AltStore（推荐）

### 步骤 1：安装 AltStore
1. 从 https://altstore.io 下载 AltStore
2. 用 sideload 方式安装到 iPhone
3. 打开 AltStore，登录你的 Apple ID

### 步骤 2：连接并安装
1. 通过 USB 连接 Mac 和 iPhone
2. 在 Mac 上打开 AltStore
3. 选择 Install App -> 选择 VlessBox.ipa

### 步骤 3：设置 VPN 描述文件（重要！）
1. 在 iPhone 设置中搜索 "描述文件"
2. 安装 VlessBox 的 VPN 配置文件
3. 设置 -> 通用 -> VPN 与设备管理
4. 信任你的开发者证书

## XUI 服务器配置

### 在 X-UI 面板中创建 Vmess 节点
1. 登录 X-UI Web 面板
2. 添加入站 -> 选择 Vmess 协议
3. 配置端口、UUID 等参数
4. 建议开启 TLS (HTTPS)

### 获取 QR Code
1. 在 X-UI 中找到创建好的节点
2. 点击节点旁边的 "QR Code" 按钮
3. 在 VlessBox 中扫描此二维码

### 手动导入方式
如果无法扫码，可以：
1. 点击 X-UI 节点详情
2. 点击 "复制链接" 按钮
3. 在 VlessBox 中点击 "粘贴" 导入

## 常见问题

### Q: 连接失败，显示 "无法连接"
A: 检查以下几点：
- 确认服务器 IP 和端口正确
- 确认 UUID 无误
- 确认服务器防火墙允许该端口
- 检查 TLS 配置是否匹配

### Q: 安装后 App 闪退
A: 确保：
- iOS 版本 >= 15.0
- 已信任开发者证书
- 描述文件已安装并启用

### Q: 9 天后 App 过期
A: 使用 AltStore 每 7 天重新签名一次
或通过 USB 连接 Mac 自动刷新

### Q: 如何更换服务器？
A: 在主界面选择其他节点即可切换
支持同时保存多个节点配置

## 网络端口要求

### 基本 Vmess 连接
- TCP 端口（默认 443 或你设置的端口）
- 如果使用 WebSocket + CDN，通过 80/443 端口

### TLS 配置推荐
- 端口 443 (HTTPS)
- 启用 TLS
- 配置 SNI (服务器名称指示)

## 高级配置

### WebSocket + TLS (CDN 隐藏)
1. 在 X-UI 中设置传输方式为 ws
2. 设置路径如 /vmess
3. 设置 Host
4. 启用 TLS
5. 在 VlessBox 中会自动识别

### 直连模式（无 TLS）
1. 在 X-UI 中关闭 TLS
2. 使用 HTTP 端口
3. VlessBox 会自动检测

## 安全提示
- 建议使用 TLS 加密传输
- 定期更换 UUID
- 不要公开分享你的配置链接
- 使用强密码保护 X-UI 面板

"# VlessBox iOS 构建与安装指南
# ============================
# 环境要求: macOS 12+、Xcode 15+、Apple ID
# 支持协议: Vmess/Vless (vmess://, vless://)
# 兼容服务器: X-UI、V2Ray、Clash Meta
"# 安装方式: Xcode 直连 / AltStore / Sideloadly / TestFlight
"# 配置导入: 二维码扫描 / 手动粘贴 / 分享链接
"# 常见问题见完整 README 文档

