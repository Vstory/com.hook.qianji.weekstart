# 钱迹强制周一 (Qianji Force Monday)

> LSPosed 模块 —— 强制钱迹记账（com.mutangtech.qianji）每周第一天为**周一**
> 状态：✅ **已成功**（用户实测打开钱迹即周一）

## 🎯 解决的问题

**钱迹记账** 在一加手机（以及其他设备）上有个烦人的 bug：设置里允许用户选择"每周起始日：周一 / 周六 / 周日"，
**但选择永远固定不住**——设置了周一，过段时间/重新打开又变回周日，烦不胜烦。

官方多次反馈未修复，于是自己动手，用 LSPosed Hook 强制锁定周一。

## 📦 下载 / 构建产物

- **GitHub Releases** 提供官方签名的 APK（发布者 keystore，私钥不公开）
- **源码自行构建**：`./build.sh`，默认 **Android debug 签名**，任何人开箱即用

| 版本 | 文件 | 说明 |
|------|------|------|
| v1.0.15 (17) | `QianjiForceMonday_v1.0.15(17).apk` | 日志精简版（当前最新） |

### 🔑 签名策略

1. **想自己构建使用** → 直接 `./build.sh`，脚本自动生成 **debug keystore（CN=Android Debug）** 签名，
   不需要 MT Manager、不需要任何证书，clone 下来即可构建安装。
2. **想发布给公众** → 用自己的 keystore 签名：`./build.sh -k /path/to/my.keystore`，
   私钥永不公开，公众通过 GitHub Releases 下载你签名好的 APK。
3. **升级时提示"签名冲突"？** → 因为两版 APK 签名不同（debug 版 vs 官方版）。
   解决办法：**先卸载旧版再安装**，或始终保持同一 keystore 构建。
   这是 Android 系统的签名机制，与模块本身无关。

> 官方 Release 版（MT/自定义签名）与本地 debug 构建版 **签名不同，无法互相覆盖安装**；
> 如需无缝升级，请始终使用同一 keystore，或直接卸载重装。

## 🧠 原理

### week 值语义（关键！）
钱迹使用 **java.util.Calendar 标准**：
- `1` = 周日
- `2` = 周一  ← 我们要强制返回的值
- `7` = 周六

### 读取链
```
getWeekStart()                          → L1 hook（直接返回 2）
  └─ c("week", 2)                       → L2 hook（key=week 返回 2）
       ├─ 已登录: va/c.l("apiconfu_week")  → va/d.getInt
       └─ 未登录: va/c.g("week")            → va/d.getInt
                                            → L3 hook（key=week/apiconfu_week 返回 2）
```

### 三重 Hook
| 层 | 目标 | 方法 | 逻辑 |
|----|------|------|------|
| L1 | `qe.c.getWeekStart()` | 静态无参 | 直接返回 2（周一） |
| L2 | `qe.c.c(String,int)` | 静态 | key="week" 返回 2（周一） |
| L3 | `va.d.getInt(String,int)` | 实例 | key="week"/"apiconfu_week" 返回 2（周一） |

> 只 hook 底层 `va.d.getInt` 不够：已登录时走 `va/c.l()` 且启动早期登录检查返回 false 时直接返回默认值，
> 根本不会到达 getInt。因此必须三重覆盖。

### 写入链（不拦截，数据安全）
```
CalendarHubPage.onMenuItemClick
  → qe.c.setWeekStart(I)Z
    → qe.c.d("week", I)Z  (登录时写入 apiconfu_week)
```
设置写入**真实发生**（MMKV 键值），模块只在**读取**时把值覆盖成周一。
不影响账单数据库，停用/卸载模块后设置恢复原始行为，完全可逆。

## 📁 项目结构
```
com.hook.qianji.weekstart/
├── AndroidManifest.xml
├── build.sh                     # 本地构建脚本 (aapt/smali/zipalign/apksigner)
├── dev-guide/                   # 🧠 开发指南（技术架构 / 踩坑记录 / 环境信息）
│   ├── architecture.md          # 读取链、写入链、三重 hook 原理
│   ├── lessons.md               # Smali 开发踩坑记录（签名 / OR逻辑 / 日志 / 混淆）
│   └── environment.md           # 目标应用信息 / LSPosed 环境 / 混淆映射表
├── src/
│   ├── assets/xposed_init       # 入口类声明
│   └── smali/com/hook/qianji/weekstart/
│       ├── HookEntry.smali      # 入口：注册三重 hook
│       ├── HookEntry$1.smali    # L3: va.d.getInt 回调
│       ├── HookEntry$2.smali    # L2: qe.c.c 回调
│       └── HookEntry$3.smali    # L1: qe.c.getWeekStart 回调
└── release/                     # 构建产物
```

## 🔧 安装使用

1. 下载 APK 安装
2. LSPosed 管理器 → 模块 → 启用「钱迹强制周一」
3. 勾选作用域：**钱迹记账**（com.mutangtech.qianji）
4. 强制停止钱迹记账 → 重新打开
5. 打开日历页（CalendarHubPage），确认周一起始 ✅

## 📜 日志确认

```
钱迹强制周一 v1.0.15: 已加载到钱迹
钱迹强制周一 v1.0.15: 已注册三重hook(getInt/qe.c.c/getWeekStart)
钱迹强制周一 v1.0.15: ★拦截getWeekStart→周一(2)   ← 每次读取触发
```

## 🧱 本地构建（可选）

```bash
chmod +x build.sh
./build.sh                          # 默认 debug 签名, 开箱即用
./build.sh -k my.keystore           # 自定义 keystore (发布者)
```
依赖：`aapt`、`smali`、`zipalign`、`apksigner`、`keytool`

支持的环境变量：`KEYSTORE_FILE` / `KEYSTORE_ALIAS` / `KEYSTORE_STORE_PASS` / `KEYSTORE_KEY_PASS`

---

## 📖 附言：一段漫长的反馈史

这个 bug 困扰了我大半年，向官方反馈了多次，始终没有修复：

> - **2025.12.30** 第一次向官方反馈
> - **2026.02.02** 第二次向官方反馈
> - **2026.08.11** 第三次向官方反馈
> - 期间还在公众号文章下反馈过几次
>
> 一直没修复，没处理，没招了。
> 自己上了。

如果你也深受"周起始日设置不生效"困扰，希望这个模块能帮到你。
也欢迎通过 Issues / PR 贡献代码。

**特别感谢 [LSPosed 团队](https://github.com/LSPosed/LSPosed)** —— 没有这个优秀的框架，就没有这个模块。🙏

## ⚠️ 免责声明
- 本模块仅供学习交流，请遵守软件许可协议
- 模块强制锁定周一，设置界面中的"周六/周日"选项将不生效（预期行为）
- 钱迹更新（类名混淆变化）可能导致模块失效，届时可参考本项目原理适配新版本
