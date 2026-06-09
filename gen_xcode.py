# -*- coding: utf-8 -*-
import hashlib, os, uuid, sys, pathlib

# 自动从脚本所在目录推导项目根目录
project_root = str(pathlib.Path(__file__).resolve().parent)
swift_files = [
    "VlessBox/VlessBoxApp.swift",
    "VlessBox/Models/VmessConfig.swift",
    "VlessBox/Services/ProxyManager.swift",
    "VlessBox/Services/QRCodeParser.swift",
    "VlessBox/Utils/SystemChecker.swift",
    "VlessBox/Views/ContentView.swift",
    "VlessBox/Views/ManualInputView.swift",
    "VlessBox/Views/QRScannerView.swift",
    "VlessBox/Assets.swift",
]
plist_files = ["VlessBox/Info.plist", "VlessBox/Entitlements.plist"]

def mkuuid(s):
    return uuid.UUID(hashlib.md5(s.encode()).hexdigest(), version=4).hex.upper()

def make_settings(extras=None):
    dq = chr(34)
    lines = [
        "        CODE_SIGN_ENTITLEMENTS = " + dq + "VlessBox/Entitlements.plist" + dq + ";",
        "        CODE_SIGN_STYLE = Automatic;",
        "        CURRENT_PROJECT_VERSION = 1;",
        "        DEVELOPMENT_TEAM = " + dq + dq + ";",
        "        INFOPLIST_FILE = " + dq + "VlessBox/Info.plist" + dq + ";",
        "        IPHONEOS_DEPLOYMENT_TARGET = 15.0;",
        "        LD_RUNPATH_SEARCH_PATHS = " + dq + chr(36) + "(inherited) @executable_path/Frameworks" + dq + ";",
        "        MARKETING_VERSION = 1.0;",
        "        PRODUCT_BUNDLE_IDENTIFIER = " + dq + "com.vlessbox.app" + dq + ";",
        "        PRODUCT_NAME = " + dq + chr(36) + "(TARGET_NAME)" + dq + ";",
        "        SWIFT_VERSION = 5.0;",
        "        TARGETED_DEVICE_FAMILY = " + dq + "1, 2" + dq + ";",
    ]
    if extras:
        lines.extend(extras)
    return chr(10).join(lines)

def main():
    L = []
    L.append("// !$*UTF8*$!")
    L.append("Version=19.2")
    L.append("ObjectVersion=55")
    L.append("SmartGroupTreeVersion=2")
    L.append("Objects {")

    bcl = mkuuid("build_config_list")
    bcr = mkuuid("build_config_rel")
    bcd = mkuuid("build_config_dbg")

    T = chr(9)
    L.append(T + bcl + " /* Build configuration list for PBXProject: Release */ = {isa = XCConfigurationList; buildConfigurations = (" + bcr + " /* Release */, " + bcd + " /* Debug */); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };")
    L.append(T + bcr + " /* Release */ = {isa = XCBuildConfiguration; buildSettings = {" + make_settings() + "}; name = Release; };")
    L.append(T + bcd + " /* Debug */ = {isa = XCBuildConfiguration; buildSettings = {" + make_settings(["        SWIFT_OPTIMIZATION_LEVEL = " + chr(34) + "-Onone" + chr(34) + ";"]) + "}; name = Debug; };")

    mg = mkuuid("main_group")
    sg = mkuuid("sources_group")
    rg = mkuuid("resources_group")
    fg = mkuuid("frameworks_group")
    pg = mkuuid("products_group")

    L.append(T + mg + " /* VlessBox */ = {isa = PBXGroup; children = (" + sg + " /* Sources */, " + rg + " /* Resources */, " + fg + " /* Frameworks */, " + pg + " /* Products */); path = VlessBox; sourceTree = " + chr(34) + "<group>" + chr(34) + "; };")
    L.append(T + pg + " /* Products */ = {isa = PBXGroup; name = Products; sourceTree = " + chr(34) + "<group>" + chr(34) + "; };")
    L.append(T + fg + " /* Frameworks */ = {isa = PBXGroup; name = Frameworks; sourceTree = " + chr(34) + "<group>" + chr(34) + "; };")

    src_refs = []
    src_builds = []
    for sf in swift_files:
        fid = mkuuid("file_" + sf)
        bid = mkuuid("build_" + sf)
        src_refs.append(fid)
        src_builds.append(bid)
        bn = os.path.basename(sf)
        L.append(T + fid + " /* " + bn + " */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = " + bn + "; sourceTree = " + chr(34) + "<group>" + chr(34) + "; };")
        L.append(T + bid + " /* " + bn + " in VlessBox */ = {isa = PBXBuildFile; fileRef = " + fid + " };")

    L.append(T + sg + " /* Sources */ = {isa = PBXGroup; children = (" + ", ".join(src_refs) + "); name = Sources; sourceTree = " + chr(34) + "<group>" + chr(34) + "; };")

    res_refs = []
    res_builds = []
    for pf in plist_files:
        fid = mkuuid("file_" + pf)
        bid = mkuuid("build_" + pf)
        res_refs.append(fid)
        res_builds.append(bid)
        bn = os.path.basename(pf)
        L.append(T + fid + " /* " + bn + " */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = text.plist.xml; path = " + bn + "; sourceTree = " + chr(34) + "<group>" + chr(34) + "; };")
        L.append(T + bid + " /* " + bn + " in VlessBox */ = {isa = PBXBuildFile; fileRef = " + fid + " };")

    L.append(T + rg + " /* Resources */ = {isa = PBXGroup; children = (" + ", ".join(res_refs) + "); name = Resources; sourceTree = " + chr(34) + "<group>" + chr(34) + "; };")

    pr = mkuuid("product_ref")
    L.append(T + pr + " /* VlessBox.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = VlessBox.app; sourceTree = BUILT_PRODUCTS_DIR; };")

    tgt = mkuuid("main_target")
    L.append(T + tgt + " /* VlessBox */ = {isa = XCLegacyProjectTarget; buildConfigurationList = " + bcl + "; buildProductsLocation = " + chr(34) + chr(36) + "(BUILD_ROOT)/BuildProductsPath" + chr(34) + "; buildRules = (); buildSettings = {" + make_settings() + "}; productName = VlessBox; productReference = " + pr + "; productType = " + chr(34) + "com.apple.product-type.application" + chr(34) + "; };")

    bps = mkuuid("sources_phase")
    bpr2 = mkuuid("resources_phase")
    bpf = mkuuid("frameworks_phase")
    L.append(T + bps + " /* Sources */ = {isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (" + ", ".join(src_builds) + "); runOnlyForDeploymentPostprocessing = 0; };")
    L.append(T + bpr2 + " /* Resources */ = {isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (" + ", ".join(res_builds) + "); runOnlyForDeploymentPostprocessing = 0; };")
    L.append(T + bpf + " /* Frameworks */ = {isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };")

    proj = mkuuid("project_obj")
    L.append(T + proj + " /* Project object */ = {isa = PBXProject; buildConfigurationList = " + bcl + "; compatibilityVersion = " + chr(34) + "Xcode 14.0" + chr(34) + "; developmentRegion = zh-CN; hasScannedForEncodings = 0; knownRegions = (en, Base, zh-Hans); mainGroup = " + mg + "; productRefGroup = " + pg + "; projectRoot = " + chr(34) + chr(34) + "; targets = (" + tgt + "); };")

    L.append("ProjectSection = {")
    L.append(T + T + proj + " = {ProjectRef = " + proj + " };")
    L.append(T + T + tgt + " = {TargetRef = " + tgt + " };")
    L.append("};")
    L.append("EndObjects }")

    outpath = os.path.join(project_root, "VlessBox.xcodeproj", "project.pbxproj")
    with open(outpath, "w", encoding="utf-8") as f:
        f.write(chr(10).join(L))
    print("Generated: " + outpath)
    print("File size: " + str(os.path.getsize(outpath)) + " bytes")
    with open(outpath, "r", encoding="utf-8") as f:
        first_line = f.readline()
    print("First line: " + repr(first_line))

    with open(outpath, "r", encoding="utf-8") as f:
        content = f.read()
    bad_markers = ["rel_settings", "dbg_settings", "tgt_settings"]
    found = [m for m in bad_markers if m in content]
    if found:
        print("ERROR: 残留占位符: " + ", ".join(found))
        sys.exit(1)
    required_keys = ["CODE_SIGN_ENTITLEMENTS", "PRODUCT_BUNDLE_IDENTIFIER", "IPHONEOS_DEPLOYMENT_TARGET"]
    missing = [k for k in required_keys if k not in content]
    if missing:
        print("ERROR: 缺少必需配置: " + ", ".join(missing))
        sys.exit(1)
    print("校验通过: 无占位符，所有必需配置已写入")

if __name__ == "__main__":
    main()

