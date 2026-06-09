# Codemagic 构建指南

## 第一步：注册 Codemagic

1. 打开 https://codemagic.io
2. 用 GitHub 账号登录
3. 免费版每月有 500 分钟构建时长

## 第二步：导入仓库

1. 点击 "Add application"
2. 选择 "Import from GitHub"
3. 搜索 ingyihua/IOS-APP 或输入仓库地址
4. 选择项目（如果有多个）
5. 点击 "Set up build"

## 第三步：配置签名（关键步骤）

### 方式 A：Apple ID 自动签名（最简单）

1. 在 Codemagic 页面，点击左侧 "App Configuration"
2. 找到 "Signing & Codes" 标签
3. 点击 "Apple signing certificates"
4. 点击 "Configure" 或 "Add"
5. 输入你的 Apple ID 邮箱和密码
6. 选择 Team（个人账号自动选择）
7. 点击 "Done"

### 方式 B：手动上传证书

如果你的项目已经在 Mac 上生成过证书：

1. 在 Mac 上打开钥匙串访问
2. 找到 "Apple Development" 或 "Apple Distribution" 证书
3. 右键 -> 导出 -> 保存为 .p12 文件
4. 输入证书密码
5. 在 Codemagic -> Settings -> Variables 中添加：

| 变量名 | 值 |
|--------|------|
| BUILD_CERTIFICATE_BASE64 | p12 文件的 Base64 字符串 |
| P12_PASSWORD | 证书密码 |
| PROVISIONING_PROFILE_BASE64 | 描述文件的 Base64 字符串 |

## 第四步：开始构建

1. 点击页面顶部的 "Trigger build"
2. 选择分支：main
3. 点击 "Start build"
4. 等待构建完成（通常 5-10 分钟）

## 第五步：下载 IPA

构建完成后：

1. 进入构建记录
2. 点击 "Artifacts" 标签
3. 下载 VlessBox.ipa 文件
4. 用 AltStore 或 Sideloadly 安装到 iPhone

## 第六步：上传到 TestFlight（可选）

1. 打开 App Store Connect: https://appstoreconnect.apple.com
2. 创建 App
3. 在 Codemagic 构建设置中开启 "Submit to TestFlight"
4. 重新触发构建
5. 在 App Store Connect 中批准发布

## 常见问题

### Q: 构建失败，签名错误
A: 检查 Apple ID 和密码是否正确，Team 是否正确

### Q: 构建超时
A: 检查代码是否有大量依赖需要编译，优化 Podfile

### Q: 无法安装到手机
A: 用 AltStore 安装前，确保：
   - iPhone 和 Mac 在同一 Wi-Fi
   - 已信任开发者证书
   - 描述文件已安装

### Q: 描述文件不匹配
A: Bundle ID 必须和证书/描述文件一致
   当前 Bundle ID: com.vlessbox.app

## 环境变量说明

在 Codemagic 中设置这些变量（Settings -> Variables）：

| 变量 | 说明 | 示例 |
|------|------|------|
| APPLE_ID | Apple ID 邮箱 | your@email.com |
| APPLE_APP_PASSWORD | App 专用密码 | abcd-efgh-ijkl-mnop |
| APPLE_TEAM_ID | Team ID | ABCDEF1234 |
| BUILD_CERTIFICATE_BASE64 | 证书 Base64 | MIIF...（长字符串）|
| P12_PASSWORD | 证书密码 | yourpassword |
| PROVISIONING_PROFILE_BASE64 | 描述文件 Base64 | MII...（长字符串）|

## Apple App 专用密码获取

1. 登录 https://appleid.apple.com
2. 登录你的 Apple ID
3. 进入 "登录和密码"
4. 生成 "应用专用密码"
5. 复制密码用于 Codemagic

