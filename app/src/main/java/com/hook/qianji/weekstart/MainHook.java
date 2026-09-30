package com.hook.qianji.weekstart;

import io.github.libxposed.api.XposedInterface;
import io.github.libxposed.api.XposedInterfaceWrapper;
import io.github.libxposed.api.XposedModule;
import io.github.libxposed.api.XposedModuleInterface;

/**
 * 钱迹记账强制周一 LSPosed 模块 — api102 入口
 *
 * Hook 目标: com.mutangtech.qianji
 * 三重 hook 覆盖所有 week 读取路径, 强制返回 2(周一):
 *   L1: qe.c.getWeekStart()          无参静态方法, 直接拦截
 *   L2: qe.c.c(String,int)           静态方法, key="week" 时拦截 (getWeekStart 直接调用)
 *   L3: va.d.getInt(String,int)      实例方法, key="week"/"apiconfu_week" 时拦截 (MMKV 底层)
 *
 * 生命周期: onModuleLoaded → onPackageReady → installHooks
 * 热重载:   onHotReloading 返回 true + onHotReloaded unhook旧handle + installHooks 重装
 */
public class MainHook extends XposedModule {

    private ClassLoader mAppClassLoader;

    // ── 构造 ─────────────────────────────────────────────
    public MainHook() {
        super();
    }

    // ── 生命周期 ──────────────────────────────────────────

    @Override
    public void onModuleLoaded(XposedModuleInterface.ModuleLoadedParam param) {
        log(4, "QianjiWeekStart", "钱迹强制周一 api102 v1.1.0 loaded");
    }

    @Override
    public void onPackageReady(XposedModuleInterface.PackageReadyParam param) {
        ClassLoader cl = param.getClassLoader();
        mAppClassLoader = cl;
        installHooks(cl);
        log(4, "QianjiWeekStart", "三重hook已安装(getWeekStart/qe.c.c/getInt)");
    }

    @Override
    public boolean onHotReloading(XposedModuleInterface.HotReloadingParam param) {
        return true;
    }

    @Override
    public void onHotReloaded(XposedModuleInterface.HotReloadedParam param) {
        // 1. 从旧 hook handle 取 app classLoader（热重载不会重放 onPackageReady）
        ClassLoader cl = null;
        var oldHandles = param.getOldHookHandles();
        if (!oldHandles.isEmpty()) {
            var handle = (XposedInterface.HookHandle) oldHandles.get(0);
            cl = handle.getExecutable().getDeclaringClass().getClassLoader();
        }
        // 2. unhook 全部旧 hooks
        for (var handle : oldHandles) {
            ((XposedInterface.HookHandle) handle).unhook();
        }
        // 3. fallback: 用保存的 mAppClassLoader
        if (cl == null) cl = mAppClassLoader;
        if (cl == null) return;
        // 4. 重装 hooks
        installHooks(cl);
        log(4, "QianjiWeekStart", "hot reloaded, hooks reinstalled");
    }

    // ── Hook 安装 ─────────────────────────────────────────

    private void installHooks(ClassLoader cl) {
        var weekStartHooker = new WeekStartHooker();
        var qeCCHooker = new QeCCHooker();
        var getIntHooker = new GetIntHooker();

        // L1: qe.c.getWeekStart() -> 2 (周一)
        hookMethod(cl, "qe.c", "getWeekStart", weekStartHooker);

        // L2: qe.c.c(String,int) key="week" -> 2 (周一)
        hookMethodStrInt(cl, "qe.c", "c", qeCCHooker);

        // L3: va.d.getInt(String,int) key="week"/"apiconfu_week" -> 2 (周一)
        hookMethodStrInt(cl, "va.d", "getInt", getIntHooker);
    }

    // ── 通用 hook 辅助 ────────────────────────────────────

    /**
     * hook 无参方法: Class.forName → getDeclaredMethod(m) → hook → PROTECTIVE → intercept
     */
    private void hookMethod(ClassLoader cl, String className, String methodName,
                            XposedInterface.Hooker hooker) {
        try {
            Class<?> clazz = Class.forName(className, false, cl);
            var method = clazz.getDeclaredMethod(methodName);
            hook(method)
                    .setExceptionMode(XposedInterface.ExceptionMode.PROTECTIVE)
                    .intercept(hooker);
        } catch (Throwable ignored) {
        }
    }

    /**
     * hook (String, int) 双参方法
     */
    private void hookMethodStrInt(ClassLoader cl, String className, String methodName,
                                  XposedInterface.Hooker hooker) {
        try {
            Class<?> clazz = Class.forName(className, false, cl);
            var method = clazz.getDeclaredMethod(methodName, String.class, int.class);
            hook(method)
                    .setExceptionMode(XposedInterface.ExceptionMode.PROTECTIVE)
                    .intercept(hooker);
        } catch (Throwable ignored) {
        }
    }
}
