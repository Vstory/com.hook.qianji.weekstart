# 钱迹强制周一 (Qianji Force Monday)

> **libxposed API 102** LSPosed 模块 —— 强制钱迹记账（com.mutangtech.qianji）每周第一天为**周一**
> 状态：✅ **已成功**（用户实测打开钱迹即周一）；v1.1.0 已重构为 api102 架构

## 🎯 解锁内容

钱迹记账的"每周起始日"设置选择**永远固定不住**（设置了周一，过段时间/重新打开又变回周日），官方多次反馈未修复。

本模块强制锁定每周第一天为**周一**：
- ✅ 日历页周一起始（读取链三重 hook，强制返回周一）
- ✅ 不拦截写入、不修改账单数据库，完全可逆（停用/卸载模块后恢复原始行为）

> 注：强制周一后，设置界面中的"周六/周日"选项将不生效（预期行为）。

## 📦 下载 / 构建产物

- **GitHub Releases** 提供官方签名的 APK（发布者 keystore，私钥不公开）
- **源码自行构建**：`./build.sh`，默认 **Android debug 签名**，任何人开箱即用

| 版本 | 文件 | 说明 |
|------|------|------|
| v1.1.0 (20) | `QianjiForceMonday_1.1.0(20).apk` | **api102 重构版**（最新，含模块描述；release/ 内置） |
| v1.0.15 (17) | `QianjiForceMonday_v1.0.15(17).apk` | 传统 Xposed API 版（旧，仅 GitHub Releases；源码备份于 dev-guide/legacy-traditional-api/） |

### 🔑 签名策略（FAQ：别人没有我的签名 / 没有 MT Manager 怎么办？）

1. **想自己构建使用** → 直接 `./build.sh`，脚本自动生成 **debug keystore（CN=Android Debug）** 签名，
   不需要 MT Manager、不需要任何证书，clone 下来即可构建安装。
2. **想发布给公众** → 用自己的 keystore 签名：`./build.sh -k /path/to/my.keystore`，
   私钥永不公开，公众通过 GitHub Releases 下载你签名好的 APK。
3. **升级时提示"签名冲突"？** → 因为两版 APK 签名不同（debug 版 vs 官方版）。
   解决办法：**先卸载旧版再安装**，或始终保持同一 keystore 构建。
   这是 Android 系统的签名机制，与模块本身无关。

> 官方 Release 版（MT/自定义签名）与本地 debug 构建版 **签名不同，无法互相覆盖安装**；
> 如需无缝升级，请始终使用同一 keystore，或直接卸载重装。

## 📁 项目结构

```
com.hook.qianji.weekstart/
├── AndroidManifest.xml            # minSdk=26；api102 无需 xposed meta-data
├── version.properties             # 版本管理（build.sh 自动递增）
├── build.sh                       # 构建: smali→aapt→打包(META-INF)→zipalign→apksigner
├── dev-guide/                      # 🧠 开发指南（技术架构 / 踩坑记录 / 环境信息）
│   ├── architecture.md            # 逆向分析 & Hook 方案：读取链、写入链、三重 hook 原理
│   ├── lessons.md                 # Smali 开发踩坑记录（签名 / OR逻辑 / 日志 / 混淆）
│   ├── environment.md             # 目标应用信息 / LSPosed 环境 / 混淆映射表
│   ├── api102-migration.md        # api102 重构记录
│   ├── CHANGELOG.md               # 更新日志
│   └── legacy-traditional-api/    # 旧版传统 Xposed API 源码备份
├── res/values/arrays.xml          # 资源（作用域数组，保留兼容）
├── src/
│   ├── meta-inf/META-INF/xposed/  # 📌 api102 模块声明
│   │   ├── java_init.list         # 入口类: com.hook.qianji.weekstart.MainHook
│   │   ├── module.prop            # minApiVersion=101 / targetApiVersion=102 / staticScope / autoHotReload
│   │   └── scope.list             # 作用域: com.mutangtech.qianji
│   └── smali/com/hook/qianji/weekstart/
│       ├── MainHook.smali         # api102 入口 (extends XposedModule) + 生命周期 + 热重载
│       ├── MainHook$WeekStartHooker.smali  # L1: qe.c.getWeekStart() 回调
│       ├── MainHook$QeCCHooker.smali       # L2: qe.c.c(String,int) 回调
│       └── MainHook$GetIntHooker.smali     # L3: va.d.getInt(String,int) 回调
└── release/                       # 构建产物
```

## 🔧 安装使用

1. 下载 APK 安装
2. LSPosed 管理器 → 模块 → 启用「钱迹强制周一」
3. 勾选作用域：**钱迹记账**（com.mutangtech.qianji）
4. 强制停止钱迹记账 → 重新打开
5. 打开日历页（CalendarHubPage），确认周一起始 ✅

## 📜 日志确认

api102 版（v1.1.0+）日志 tag 为 `QianjiWeekStart`：

```
QianjiWeekStart: 钱迹强制周一 api102 v1.1.0 loaded              ← onModuleLoaded
QianjiWeekStart: 三重hook已安装(getWeekStart/qe.c.c/getInt)      ← onPackageReady
```

> api102 架构下 Hooker 回调无 log 通道（见 dev-guide/lessons.md C2），
> 拦截是否命中以界面效果为准（日历页周一起始 = 生效）。

## 🧱 本地构建（可选）

```bash
chmod +x build.sh
./build.sh                          # 默认 debug 签名, 开箱即用
./build.sh -k my.keystore           # 自定义 keystore (发布者)
```
依赖：`aapt`、`smali`、`zipalign`、`apksigner`、`keytool`

支持的环境变量：`KEYSTORE_FILE` / `KEYSTORE_ALIAS` / `KEYSTORE_STORE_PASS` / `KEYSTORE_KEY_PASS`

---

## 📖 背景

这个 bug 困扰了大半年，向官方多次反馈始终未修复（详见 dev-guide/CHANGELOG.md），于是自己动手。

**特别感谢 [LSPosed 团队](https://github.com/LSPosed/LSPosed)** —— 没有这个优秀的框架，就没有这个模块。🙏

## ⚠️ 免责声明
- 本模块仅供学习交流，请遵守软件许可协议
- 模块强制锁定周一，设置界面中的"周六/周日"选项将不生效（预期行为）
- 钱迹更新（类名混淆变化）可能导致模块失效，届时可参考本项目原理适配新版本
