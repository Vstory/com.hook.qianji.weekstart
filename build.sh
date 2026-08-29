#!/bin/bash
#
# 钱迹强制周一 LSPosed 模块构建脚本
# v1.0.15(17) - 三重 hook (getWeekStart / qe.c.c / va.d.getInt) + 日志精简
#
# 依赖: aapt, smali, zipalign, apksigner, keytool
# 用法:
#   ./build.sh                     # 默认使用自动生成的 debug 签名 (开箱即用)
#   ./build.sh -k my.keystore      # 使用自定义 keystore 签名 (发布者)
#
# 环境变量 (或 -k/-a 参数):
#   KEYSTORE_FILE    keystore 路径
#   KEYSTORE_ALIAS   别名 (默认 androiddebugkey)
#   KEYSTORE_STORE_PASS  store 密码 (默认 android)
#   KEYSTORE_KEY_PASS      key 密码   (默认 android)
#
# 产出: release/QianjiForceMonday_v1.0.15(17).apk
#
# 签名策略说明:
#   - 默认 debug 签名 (CN=Android Debug): 任何人 clone 后无需任何证书即可构建安装
#   - 自定义 keystore: 发布者用自己的私钥签名, 私钥永不公开
#   - 注意: debug 签名版与发布版(不同签名)无法互相覆盖安装, 升级需先卸载或保持同一签名
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

BUILD_DIR="build"
RELEASE_DIR="release"
SRC_DIR="src"
RES_DIR="res"

PACKAGE_NAME="com.hook.qianji.weekstart"
VERSION_NAME="1.0.15"
VERSION_CODE=17
OUTPUT_NAME="QianjiForceMonday_v${VERSION_NAME}(${VERSION_CODE}).apk"

# ========== 解析参数 ==========
CUSTOM_KEYSTORE=""
while [ $# -gt 0 ]; do
    case "$1" in
        -k|--keystore)
            CUSTOM_KEYSTORE="$2"; shift 2 ;;
        -a|--alias)
            KEYSTORE_ALIAS="$2"; shift 2 ;;
        *)
            echo "未知参数: $1"; exit 1 ;;
    esac
done

# ========== 签名配置 (默认 debug) ==========
KEYSTORE_FILE="${KEYSTORE_FILE:-$CUSTOM_KEYSTORE}"
KEYSTORE_ALIAS="${KEYSTORE_ALIAS:-androiddebugkey}"
KEYSTORE_STORE_PASS="${KEYSTORE_STORE_PASS:-android}"
KEYSTORE_KEY_PASS="${KEYSTORE_KEY_PASS:-android}"

# 查找 android.jar
ANDROID_JAR="/workspace/tools/android-sdk/platforms/android-34/android.jar"
if [ ! -f "$ANDROID_JAR" ]; then
    ANDROID_JAR="/usr/lib/android-sdk/platforms/android-23/android.jar"
fi
echo "使用 android.jar: $ANDROID_JAR"

# ========== 1. 清理 ==========
echo "[1/7] 清理构建目录..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$RELEASE_DIR"

# ========== 2. 编译资源 ==========
echo "[2/7] 编译资源..."
TEMP_MANIFEST="$BUILD_DIR/AndroidManifest.xml"
cat > "$TEMP_MANIFEST" << EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$PACKAGE_NAME"
    android:versionCode="$VERSION_CODE"
    android:versionName="$VERSION_NAME">
    <uses-sdk android:minSdkVersion="26" android:targetSdkVersion="35" />
    <application android:label="钱迹强制周一">
        <meta-data android:name="xposeddescription" android:value="强制钱迹记账每周第一天为周一(三重MMKV拦截)" />
        <meta-data android:name="xposedmodule" android:value="true" />
        <meta-data android:name="xposedminversion" android:value="93" />
        <meta-data android:name="xposedscope" android:value="com.mutangtech.qianji" />
    </application>
</manifest>
EOF

# 编译资源生成 R.java (可选，模块无Java代码引用资源时不需要)
mkdir -p "$BUILD_DIR/gen"
aapt package -f -m \
    -J "$BUILD_DIR/gen" \
    -M "$TEMP_MANIFEST" \
    -S "$RES_DIR" \
    -I "$ANDROID_JAR" \
    --non-constant-id 2>/dev/null || echo "      (R.java 生成跳过/失败, 继续)"

# ========== 3. 编译 Smali ==========
echo "[3/7] 编译 Smali → classes.dex..."
smali assemble "$SRC_DIR/smali" -o "$BUILD_DIR/classes.dex"
DEX_SIZE=$(wc -c < "$BUILD_DIR/classes.dex")
echo "      classes.dex: ${DEX_SIZE} bytes"

# ========== 4. 打包 APK ==========
echo "[4/7] 打包未签名 APK..."
cd "$SCRIPT_DIR"

aapt package -f \
    -M "$SCRIPT_DIR/$BUILD_DIR/AndroidManifest.xml" \
    -S "$SCRIPT_DIR/$RES_DIR" \
    -A "$SCRIPT_DIR/src/assets" \
    -I "$ANDROID_JAR" \
    -F "$SCRIPT_DIR/$RELEASE_DIR/${OUTPUT_NAME}.unsigned.apk"

# 添加 classes.dex 到 APK (需在包含classes.dex的目录执行)
cd "$BUILD_DIR"
aapt add "$SCRIPT_DIR/$RELEASE_DIR/${OUTPUT_NAME}.unsigned.apk" classes.dex

cd "$SCRIPT_DIR"

# ========== 5. Zipalign ==========
echo "[5/7] Zipalign 对齐..."
mv "$RELEASE_DIR/${OUTPUT_NAME}.unsigned.apk" "$BUILD_DIR/unsigned.apk"
zipalign -f 4 "$BUILD_DIR/unsigned.apk" "$BUILD_DIR/aligned.apk"

# ========== 6. 准备 keystore ==========
echo "[6/7] 准备签名证书..."
if [ -n "$KEYSTORE_FILE" ] && [ -f "$KEYSTORE_FILE" ]; then
    echo "      使用自定义 keystore: $KEYSTORE_FILE (alias=$KEYSTORE_ALIAS)"
else
    # 默认 debug keystore: 首次自动生成, 之后复用
    KEYSTORE_FILE="$BUILD_DIR/debug.keystore"
    if [ ! -f "$KEYSTORE_FILE" ]; then
        echo "      生成 debug keystore (CN=Android Debug)..."
        keytool -genkeypair -v \
            -keystore "$KEYSTORE_FILE" \
            -alias androiddebugkey \
            -keyalg RSA \
            -keysize 2048 \
            -validity 10000 \
            -storepass android \
            -keypass android \
            -dname "CN=Android Debug,O=Android,C=US" >/dev/null 2>&1
    fi
    echo "      使用 debug keystore: $KEYSTORE_FILE"
fi

# ========== 7. 签名 ==========
echo "[7/7] 签名 APK..."
apksigner sign \
    --ks "$KEYSTORE_FILE" \
    --ks-key-alias "$KEYSTORE_ALIAS" \
    --ks-pass pass:"$KEYSTORE_STORE_PASS" \
    --key-pass pass:"$KEYSTORE_KEY_PASS" \
    --out "$RELEASE_DIR/$OUTPUT_NAME" \
    "$BUILD_DIR/aligned.apk"

echo ""
echo "构建完成!"
echo "APK: $RELEASE_DIR/$OUTPUT_NAME"
echo ""
echo "签名信息:"
apksigner verify --print-certs "$RELEASE_DIR/$OUTPUT_NAME" 2>/dev/null | grep -E "Signer #1 certificate DN|Signer #1 certificate SHA-256" || true
echo ""
echo "安装步骤:"
echo "1. 将 APK 复制到手机"
echo "2. 在 LSPosed 管理器中启用/更新模块"
echo "3. 勾选钱迹记账作为作用域"
echo "4. 强制停止并重新打开钱迹记账"
echo ""
echo "提示: 若手机已安装官方 Release 版(不同签名), 直接安装本 APK 会提示签名冲突;"
echo "      请先卸载旧版再安装, 或使用与官方相同的 keystore 重新构建 (-k 参数)。"
