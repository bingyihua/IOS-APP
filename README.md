# VlessBox - iOS Vmess 代理客户端

一个支持 Vmess/Vless 协议的 iOS 客户端，可以通过扫描二维码一键导入配置，连接 X-UI 服务器。

## 功能特性

- **Vmess 协议支持** - 完全兼容 V2Ray/Xray 的 Vmess 协议
- **Vless 协议支持** - 支持 Vless 协议及多种传输方式
- **二维码扫描** - 一键扫描 Vmess/vless:// 链接
- **手动导入** - 粘贴配置链接或 YAML 配置
- **多节点管理** - 保存和管理多个服务器配置
- **TLS 加密** - 支持 WSS/HTTPS 传输
- **WebSocket 传输** - 支持 CDN 隐藏和流量伪装
- **自动重连** - 网络恢复后自动重连
- **流量统计** - 实时显示上传/下载流量

## 项目结构

`
VlessBox/
├── VlessBox/                     # Swift 源代码
│   ├── VlessBoxApp.swift         # 应用入口
│   ├── Info.plist                # 应用配置
│   ├── Entitlements.plist        # 权限声明
│   ├── Models/
│   │   └── VmessConfig.swift     # Vmess 配置模型
│   ├── Services/
│   │   ├── ProxyManager.swift    # 代理管理核心
│   │   └── QRCodeParser.swift    # 二维码解析
│   ├── Utils/
│   │   └── SystemChecker.swift   # 系统检查工具
│   └── Views/
│       ├── ContentView.swift     # 主界面
│       ├── ManualInputView.swift # 手动输入
│       └── QRScannerView.swift   # 二维码扫描
├── VlessBoxTests/                # 测试文件
├── Resources/                    # 资源文件
├── VlessBox.xcodeproj/           # Xcode 项目
├── build-ipa.sh                  # IPA 构建脚本
├── gen_xcode.py                  # 项目生成器
├── BUILD_GUIDE.md                # 详细构建指南
└── README.md                     # 本文件
`

## 快速开始

### 方法一：Xcode 直接运行（推荐）

1. 将项目复制到 Mac
2. 打开 VlessBox.xcodeproj
3. 配置你的 Apple ID 签名
4. 连接 iPhone，点击运行

### 方法二：构建 IPA 安装

`ash
cd VlessBox
bash build-ipa.sh
`

然后用 AltStore 安装到 iPhone

### 方法三：通过 TestFlight

1. 注册 Apple Developer Program
2. 在 App Store Connect 创建应用
3. 上传 IPA 到 TestFlight
4. 邀请测试人员

## X-UI 服务器配置

### 1. 创建 Vmess 节点

在 X-UI 面板中：
- 添加入站 -> 选择 Vmess
- 设置端口（推荐 443）
- 设置 UUID
- 启用 TLS

### 2. 获取 QR Code

- 在 X-UI 中找到创建好的节点
- 点击节点旁边的 "QR Code" 按钮
- 在 VlessBox 中扫描此二维码

### 3. 手动导入

- 点击 "复制链接" 按钮
- 在 VlessBox 中粘贴

## 支持的协议

| 协议 | 传输 | TLS | CDN |
|------|------|-----|-----|
| Vmess | TCP | 支持 | 支持 (WS) |
| Vless | TCP | 支持 | 支持 (WS) |
| Vless | WebSocket | 支持 | 支持 |
| Vless | gRPC | 支持 | 支持 |
| Vless | HTTP Upgrade | 支持 | 支持 |

## 常见问题

### 连接失败
- 检查服务器 IP 和端口
- 确认 UUID 无误
- 确认 TLS 配置匹配
- 检查服务器防火墙

### App 安装失败
- 确保 iOS >= 15.0
- 已信任开发者证书
- 描述文件已安装

### 9 天后过期
- 用 AltStore 每 7 天重新签名
- 或通过 USB 连接 Mac 自动刷新

## 构建要求

- macOS 12+ (Monterey)
- Xcode 15+
- Apple ID (免费版即可)
- iPhone/iPad (iOS 15+)

## 许可证

MIT License

## 免责声明

本软件仅用于学习和研究目的。请确保你的使用符合当地法律法规。

