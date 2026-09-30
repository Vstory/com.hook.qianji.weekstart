#!/bin/bash
# ============================================================
# 钱迹强制周一 LSPosed 模块 - api102 构建脚本
# v1.1.0 - 基于 io.github.libxposed.api (libxposed API 102)
# ============================================================
# 依赖: aapt, smali, zipalign, apksigner, keytool
# 用法:
#   ./build.sh                     # patch: versionCode+1, versionName 不变
#   ./build.sh minor               # minor: 次版本+1, code+1
#   ./build.sh major               # major: 主版本+1, code+1
#   ./build.sh -k my.keystore patch   # 自定义 keystore 签名
#
# 环境变量 (或 -k/-a 参数):
#   KEYSTORE_FILE / KEYSTORE_ALIAS / KEYSTORE_STORE_PASS / KEYSTORE_KEY_PASS
#
# 签名策略:
#   - 默认 debug 签名 (CN=Android Debug): 任何人 clone 后无需证书即可构建安装
#   - 自定义 keystore: 发布者用自己的私钥签名, 私钥永不公开
# ============================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

MODULE_NAME="QianjiForceMonday"
AAPT="/usr/bin/aapt"
ANDROID_JAR="/workspace/tools/android-sdk/platforms/android-34/android.jar"
if [ ! -f "$ANDROID_JAR" ]; then
    ANDROID_JAR="/usr/lib/android-sdk/platforms/android-23/android.jar"
fi
ZIPALIGN="/usr/bin/zipalign"
APKSIGNER="/usr/bin/apksigner"
SMALI="/usr/bin/smali"

# ---------- 解析参数 ----------
CUSTOM_KEYSTORE=""
BUMP="patch"
while [ $# -gt 0 ]; do
    case "$1" in
        -k|--keystore) CUSTOM_KEYSTORE="$2"; shift 2 ;;
        -a|--alias)    KEYSTORE_ALIAS="$2"; shift 2 ;;
        patch|minor|major) BUMP="$1"; shift ;;
        *) echo "未知参数: $1 (支持 patch|minor|major 和 -k keystore)"; exit 1 ;;
    esac
done

# ---------- 签名配置 (默认 debug) ----------
KEYSTORE_FILE="${KEYSTORE_FILE:-$CUSTOM_KEYSTORE}"
KEYSTORE_ALIAS="${KEYSTORE_ALIAS:-androiddebugkey}"
KEYSTORE_STORE_PASS="${KEYSTORE_STORE_PASS:-android}"
KEYSTORE_KEY_PASS="${KEYSTORE_KEY_PASS:-android}"

# ---------- 版本管理 ----------
VERSION_FILE="version.properties"
if [ ! -f "$VERSION_FILE" ]; then
    printf 'versionName=1.1.0\nversionCode=18\n' > "$VERSION_FILE"
fi
VERSION_NAME=$(grep '^versionName=' "$VERSION_FILE" | cut -d= -f2)
VERSION_CODE=$(grep '^versionCode=' "$VERSION_FILE" | cut -d= -f2)

case "$BUMP" in
    patch) VERSION_CODE=$((VERSION_CODE + 1)) ;;
    minor) VERSION_NAME=$(echo "$VERSION_NAME" | awk -F. '{print $1"."$2+1".0"}'); VERSION_CODE=$((VERSION_CODE + 1)) ;;
    major) VERSION_NAME=$(echo "$VERSION_NAME" | awk -F. '{print $1+1".0.0"}'); VERSION_CODE=$((VERSION_CODE + 1)) ;;
esac
printf 'versionName=%s\nversionCode=%s\n' "$VERSION_NAME" "$VERSION_CODE" > "$VERSION_FILE"
OUT="release/${MODULE_NAME}_${VERSION_NAME}(${VERSION_CODE}).apk"
echo "构建版本: ${VERSION_NAME}(${VERSION_CODE})"

# ---------- 写回 Manifest 版本号 ----------
sed -i "s/android:versionCode=\"[0-9]*\"/android:versionCode=\"$VERSION_CODE\"/; s/android:versionName=\"[^\"]*\"/android:versionName=\"$VERSION_NAME\"/" AndroidManifest.xml

# ---------- 编译 ----------
echo "[1/5] smali 编译..."
rm -rf build
mkdir -p build/dex
"$SMALI" assemble src/smali -o build/dex/classes.dex

echo "[2/5] aapt 编译资源(生成二进制AXML)..."
mkdir -p build/clean
"$AAPT" package -f -M AndroidManifest.xml -S res \
    -I "$ANDROID_JAR" -F build/base.apk
cd build/clean
unzip -o ../base.apk
# api102 模块配置: META-INF/xposed/{java_init.list, module.prop, scope.list}
cp -r ../../src/meta-inf/META-INF .
cp ../dex/classes.dex .
rm -rf META-INF/*.SF META-INF/*.RSA META-INF/*.MF 2>/dev/null || true
cd ../..

# ---------- 打包（resources.arsc 必须未压缩+对齐）----------
echo "[3/5] 打包 (resources.arsc store 模式)..."
rm -f "$OUT" release/tmp_unsigned.apk release/aligned.apk
cd build/clean
zip -r ../../release/tmp_unsigned.apk \
    AndroidManifest.xml resources.arsc classes.dex \
    META-INF/xposed/java_init.list META-INF/xposed/module.prop META-INF/xposed/scope.list
# resources.arsc 重压为未压缩(store)
zip -d ../../release/tmp_unsigned.apk resources.arsc
zip -0 ../../release/tmp_unsigned.apk resources.arsc
cd ../..

echo "[4/5] zipalign 对齐..."
"$ZIPALIGN" -f 4 release/tmp_unsigned.apk release/aligned.apk

echo "[5/5] apksigner 签名..."
if [ -n "$KEYSTORE_FILE" ] && [ -f "$KEYSTORE_FILE" ]; then
    echo "      使用自定义 keystore: $KEYSTORE_FILE (alias=$KEYSTORE_ALIAS)"
else
    KEYSTORE_FILE="build/debug.keystore"
    if [ ! -f "$KEYSTORE_FILE" ]; then
        echo "      生成 debug keystore (CN=Android Debug)..."
        keytool -genkeypair -v -keystore "$KEYSTORE_FILE" -storepass android \
            -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 \
            -validity 10000 -dname "CN=Android Debug,O=Android,C=US" 2>/dev/null
    fi
    echo "      使用 debug keystore: $KEYSTORE_FILE"
fi
"$APKSIGNER" sign --ks "$KEYSTORE_FILE" --ks-pass pass:"$KEYSTORE_STORE_PASS" \
    --key-pass pass:"$KEYSTORE_KEY_PASS" --ks-key-alias "$KEYSTORE_ALIAS" \
    --out "$OUT" release/aligned.apk

rm -f release/tmp_unsigned.apk release/aligned.apk
echo ""
echo "✅ 完成: $OUT"
echo ""
echo "签名信息:"
"$APKSIGNER" verify --print-certs "$OUT" 2>/dev/null | grep -E "Signer #1 certificate DN|Signer #1 certificate SHA-256" || true
echo ""
echo "安装步骤:"
echo "1. 将 APK 复制到手机"
echo "2. 在 LSPosed 管理器中启用/更新模块 (作用域自动=钱迹记账)"
echo "3. 强制停止并重新打开钱迹记账"
echo ""
echo "提示: 若手机已安装官方 Release 版(不同签名), 直接安装本 APK 会提示签名冲突;"
echo "      请先卸载旧版再安装, 或使用与官方相同的 keystore 重新构建 (-k 参数)。"
