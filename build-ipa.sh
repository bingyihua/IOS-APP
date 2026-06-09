#!/bin/bash

# VlessBox IPA Build Script
# 用于在 macOS 上构建和签名 VlessBox IPA

set -e

# ========== 配置 ==========
APP_NAME=\"VlessBox\"
BUNDLE_ID=\"com.vlessbox.app\"
TEAM_ID=\"\"  # 填写你的 Team ID
SCHEME=\"VlessBox\"
BUILD_DIR=\"build\"
CONFIGURATION=\"Release\"

# ========== 颜色输出 ==========
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
NC='\\033[0m'

echo \"======================================\"
echo \"  VlessBox IPA 构建脚本\"
echo \"======================================\"

# ========== 检查前提条件 ==========
echo \"\"
echo \"[1/5] 检查前提条件...\"

if ! command -v xcodebuild &> /dev/null; then
    echo -e \"错误: 未找到 xcodebuild，请安装 Xcode\"
    exit 1
fi

if [ -z \"\" ]; then
    echo -e \"警告: 未设置 TEAM_ID，使用自动签名\"
fi

echo -e \"✓ Xcode 已安装\"

# ========== 清理构建目录 ==========
echo \"\"
echo \"[2/5] 清理构建目录...\"
rm -rf \"\"
mkdir -p \"\"
echo -e \"✓ 清理完成\"

# ========== 构建项目 ==========
echo \"\"
echo \"[3/5] 开始构建...\"

# 基本构建命令
xcodebuild clean build \
    -scheme \"\" \
    -configuration \"\" \
    -derivedDataPath \"/DerivedData\" \
    -destination \"generic/platform=iOS\" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    2>&1 | tee \"/build.log\"

if [  -ne 0 ]; then
    echo -e \"✗ 构建失败，请查看 /build.log\"
    exit 1
fi

echo -e \"✓ 构建完成\"

# ========== 打包 IPA ==========
echo \"\"
echo \"[4/5] 打包 IPA...\"

# 找到 .app 文件
APP_PATH=\"\"

if [ -z \"\" ] || [ ! -d \"\" ]; then
    echo -e \"错误: 未找到编译产物\"
    exit 1
fi

# 创建 Payload 目录
PAYLOAD_DIR=\"/Payload\"
mkdir -p \"\"
cp -R \"\" \"/\"

# 打包成 IPA
cd \"\"
zip -qr \".ipa\" Payload/
rm -rf Payload

echo -e \"✓ IPA 打包完成\"
echo -e \"  IPA 文件位置: /.ipa\"

# ========== 签名（可选）==========
echo \"\"
echo \"[5/5] 签名配置...\"

if [ -n \"\" ]; then
    echo -e \"使用 Developer/Enterprise 证书签名（需要安装证书）\"
    echo \"签名步骤：\"
    echo \"1. 安装你的开发证书\"
    echo \"2. 运行: codesign -s \\\"\\\" -fv --entitlements VlessBox/Entitlements.plist Payload/.app\"
    echo \"3. 重新打包: cd build && zip -qr _signed.ipa Payload/\"
    
    # 使用 Ad-Hoc 签名示例
    codesign -f -s \"\" --entitlements \"../VlessBox/VlessBox/Entitlements.plist\" \"/.app\"
    
    # 重新打包
    rm \".ipa\"
    zip -qr \"_signed.ipa\" Payload/
    rm -rf Payload
    
    echo -e \"✓ 已使用 Ad-Hoc 签名\"
else
    echo -e \"跳过签名（需要 Team ID 和开发证书）\"
    echo \"未签名的 IPA 可以通过以下方式分发：\"
    echo \"- AltStore: 需要 Apple ID，9 天有效期\"
    echo \"- 企业证书: 长期有效\"
    echo \"- Apple Developer: App Store 分发，1 年有效期\"
fi

echo \"\"
echo -e \"======================================\"
echo -e \"  构建完成！\"
echo -e \"======================================\"
echo \"\"
echo \"产物位置: /.ipa\"
echo \"构建日志: /build.log\"
echo \"\"
echo \"安装方式：\"
echo \"1. AltStore: 打开 AltStore -> 安装 -> 选择 .ipa\"
echo \"2. TestFlight: 上传到 Apple 进行 Beta 测试\"
echo \"3. AirDrop: 直接从 Mac 发送到 iPhone\"
echo \"\"
