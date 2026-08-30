#
# 钱迹记账强制周一 LSPosed 模块 - api102 入口（重构版 v1.1.0）
# 基于 io.github.libxposed.api（libxposed API 102），禁止传统 de.robv.android.xposed.* API
#
# Hook 目标: com.mutangtech.qianji
# 三重 hook 覆盖所有 week 读取路径, 强制返回 2(周一):
#   L1: qe.c.getWeekStart()          无参静态方法, 直接拦截
#   L2: qe.c.c(String,int)           静态方法, key="week" 时拦截 (getWeekStart 直接调用)
#   L3: va.d.getInt(String,int)      实例方法, key="week"/"apiconfu_week" 时拦截 (MMKV 底层)
#
# 生命周期: onModuleLoaded → onPackageReady → installHooks
# 热重载:   onHotReloading 返回 true + onHotReloaded unhook旧handle + installHooks 重装
#
.class public Lcom/hook/qianji/weekstart/MainHook;
.super Lio/github/libxposed/api/XposedModule;

# 保存被 hook 应用的 classLoader（热重载 fallback 用，主路径从旧 hook handle 取）
.field private mAppClassLoader:Ljava/lang/ClassLoader;


# direct methods
.method public constructor <init>()V
    .registers 1

    invoke-direct {p0}, Lio/github/libxposed/api/XposedModule;-><init>()V

    return-void
.end method

# 通用 hook 辅助方法（无参方法版）:
#   Class.forName(cls, false, cl) → getDeclaredMethod(m, new Class[0])
#   → hook(method).setExceptionMode(PROTECTIVE).intercept(hooker)
# 4 参数 + this = 5 个寄存器，invoke-direct 普通形式上限内
# 单个 hook 失败只跳过该 hook，不影响其它 hook
.method private hookMethod(Ljava/lang/ClassLoader;Ljava/lang/String;Ljava/lang/String;Lio/github/libxposed/api/XposedInterface$Hooker;)V
    .registers 7

    :try_start
    # Class.forName(className, false, classLoader) — initialize 必须 false！只加载类不触发 <clinit>
    const/4 v0, 0x0

    invoke-static {p2, v0, p1}, Ljava/lang/Class;->forName(Ljava/lang/String;ZLjava/lang/ClassLoader;)Ljava/lang/Class;

    move-result-object v0

    # clazz.getDeclaredMethod(methodName, new Class[0])
    const/4 v1, 0x0

    new-array v1, v1, [Ljava/lang/Class;

    invoke-virtual {v0, p3, v1}, Ljava/lang/Class;->getDeclaredMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    # hook(method) -> HookBuilder (XposedInterfaceWrapper 方法, invoke-virtual)
    invoke-virtual {p0, v0}, Lio/github/libxposed/api/XposedInterfaceWrapper;->hook(Ljava/lang/reflect/Executable;)Lio/github/libxposed/api/XposedInterface$HookBuilder;

    move-result-object v0

    # builder.setExceptionMode(ExceptionMode.PROTECTIVE) -> HookBuilder (接口方法, invoke-interface)
    sget-object v1, Lio/github/libxposed/api/XposedInterface$ExceptionMode;->PROTECTIVE:Lio/github/libxposed/api/XposedInterface$ExceptionMode;

    invoke-interface {v0, v1}, Lio/github/libxposed/api/XposedInterface$HookBuilder;->setExceptionMode(Lio/github/libxposed/api/XposedInterface$ExceptionMode;)Lio/github/libxposed/api/XposedInterface$HookBuilder;

    move-result-object v0

    # builder.intercept(hooker) -> HookHandle (接口方法, invoke-interface)
    invoke-interface {v0, p4}, Lio/github/libxposed/api/XposedInterface$HookBuilder;->intercept(Lio/github/libxposed/api/XposedInterface$Hooker;)Lio/github/libxposed/api/XposedInterface$HookHandle;
    :try_end
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :catch_ignore

    :catch_ignore
    return-void
.end method

# 通用 hook 辅助方法（(String,int) 双参方法版）: 同 hookMethod，但 getDeclaredMethod 用 [String.class, int.class]
.method private hookMethodStrInt(Ljava/lang/ClassLoader;Ljava/lang/String;Ljava/lang/String;Lio/github/libxposed/api/XposedInterface$Hooker;)V
    .registers 9

    :try_start
    # Class.forName(className, false, classLoader)
    const/4 v0, 0x0

    invoke-static {p2, v0, p1}, Ljava/lang/Class;->forName(Ljava/lang/String;ZLjava/lang/ClassLoader;)Ljava/lang/Class;

    move-result-object v0

    # clazz.getDeclaredMethod(methodName, new Class[]{String.class, int.class})
    const/4 v1, 0x2

    new-array v1, v1, [Ljava/lang/Class;

    const-class v2, Ljava/lang/String;

    const/4 v3, 0x0

    aput-object v2, v1, v3

    sget-object v2, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    const/4 v3, 0x1

    aput-object v2, v1, v3

    invoke-virtual {v0, p3, v1}, Ljava/lang/Class;->getDeclaredMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    # hook(method) -> HookBuilder
    invoke-virtual {p0, v0}, Lio/github/libxposed/api/XposedInterfaceWrapper;->hook(Ljava/lang/reflect/Executable;)Lio/github/libxposed/api/XposedInterface$HookBuilder;

    move-result-object v0

    # builder.setExceptionMode(ExceptionMode.PROTECTIVE) -> HookBuilder
    sget-object v1, Lio/github/libxposed/api/XposedInterface$ExceptionMode;->PROTECTIVE:Lio/github/libxposed/api/XposedInterface$ExceptionMode;

    invoke-interface {v0, v1}, Lio/github/libxposed/api/XposedInterface$HookBuilder;->setExceptionMode(Lio/github/libxposed/api/XposedInterface$ExceptionMode;)Lio/github/libxposed/api/XposedInterface$HookBuilder;

    move-result-object v0

    # builder.intercept(hooker) -> HookHandle
    invoke-interface {v0, p4}, Lio/github/libxposed/api/XposedInterface$HookBuilder;->intercept(Lio/github/libxposed/api/XposedInterface$Hooker;)Lio/github/libxposed/api/XposedInterface$HookHandle;
    :try_end
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :catch_ignore

    :catch_ignore
    return-void
.end method

# 安装全部 hooks（onPackageReady 与 onHotReloaded 共用）
.method private installHooks(Ljava/lang/ClassLoader;)V
    .registers 10

    # 复用 Hooker 实例（无状态，可多个方法共用；这里各用独立实例便于区分）
    new-instance v1, Lcom/hook/qianji/weekstart/MainHook$WeekStartHooker;

    invoke-direct {v1}, Lcom/hook/qianji/weekstart/MainHook$WeekStartHooker;-><init>()V

    new-instance v2, Lcom/hook/qianji/weekstart/MainHook$QeCCHooker;

    invoke-direct {v2}, Lcom/hook/qianji/weekstart/MainHook$QeCCHooker;-><init>()V

    new-instance v3, Lcom/hook/qianji/weekstart/MainHook$GetIntHooker;

    invoke-direct {v3}, Lcom/hook/qianji/weekstart/MainHook$GetIntHooker;-><init>()V

    # ==========================================
    # L1: qe.c.getWeekStart() -> 2 (周一)
    # ==========================================
    const-string v4, "qe.c"

    const-string v5, "getWeekStart"

    invoke-direct {p0, p1, v4, v5, v1}, Lcom/hook/qianji/weekstart/MainHook;->hookMethod(Ljava/lang/ClassLoader;Ljava/lang/String;Ljava/lang/String;Lio/github/libxposed/api/XposedInterface$Hooker;)V

    # ==========================================
    # L2: qe.c.c(String,int) key="week" -> 2 (周一)
    # ==========================================
    const-string v4, "qe.c"

    const-string v5, "c"

    invoke-direct {p0, p1, v4, v5, v2}, Lcom/hook/qianji/weekstart/MainHook;->hookMethodStrInt(Ljava/lang/ClassLoader;Ljava/lang/String;Ljava/lang/String;Lio/github/libxposed/api/XposedInterface$Hooker;)V

    # ==========================================
    # L3: va.d.getInt(String,int) key="week"/"apiconfu_week" -> 2 (周一)
    # ==========================================
    const-string v4, "va.d"

    const-string v5, "getInt"

    invoke-direct {p0, p1, v4, v5, v3}, Lcom/hook/qianji/weekstart/MainHook;->hookMethodStrInt(Ljava/lang/ClassLoader;Ljava/lang/String;Ljava/lang/String;Lio/github/libxposed/api/XposedInterface$Hooker;)V

    return-void
.end method


# virtual methods
.method public onModuleLoaded(Lio/github/libxposed/api/XposedModuleInterface$ModuleLoadedParam;)V
    .registers 5

    # log(Log.INFO, "QianjiWeekStart", "api102 module loaded")
    const/4 v0, 0x4

    const-string v1, "QianjiWeekStart"

    const-string v2, "钱迹强制周一 api102 v1.1.0 loaded"

    invoke-virtual {p0, v0, v1, v2}, Lio/github/libxposed/api/XposedInterfaceWrapper;->log(ILjava/lang/String;Ljava/lang/String;)V

    return-void
.end method

.method public onPackageReady(Lio/github/libxposed/api/XposedModuleInterface$PackageReadyParam;)V
    .registers 6

    # 获取目标包 classLoader 并保存（热重载 fallback 用）
    invoke-interface {p1}, Lio/github/libxposed/api/XposedModuleInterface$PackageReadyParam;->getClassLoader()Ljava/lang/ClassLoader;

    move-result-object v0

    iput-object v0, p0, Lcom/hook/qianji/weekstart/MainHook;->mAppClassLoader:Ljava/lang/ClassLoader;

    # 安装全部 hooks
    invoke-direct {p0, v0}, Lcom/hook/qianji/weekstart/MainHook;->installHooks(Ljava/lang/ClassLoader;)V

    # log(Log.INFO, "QianjiWeekStart", "hooks installed")
    const/4 v1, 0x4

    const-string v2, "QianjiWeekStart"

    const-string v3, "三重hook已安装(getWeekStart/qe.c.c/getInt)"

    invoke-virtual {p0, v1, v2, v3}, Lio/github/libxposed/api/XposedInterfaceWrapper;->log(ILjava/lang/String;Ljava/lang/String;)V

    return-void
.end method

# 允许热重载（接口默认返回 false，不覆写会拒绝热重载请求）
.method public onHotReloading(Lio/github/libxposed/api/XposedModuleInterface$HotReloadingParam;)Z
    .registers 3

    const/4 v0, 0x1

    return v0
.end method

# 热重载完成后：从旧 hook handle 取 classLoader → unhook 全部旧 hooks → installHooks 重装
.method public onHotReloaded(Lio/github/libxposed/api/XposedModuleInterface$HotReloadedParam;)V
    .registers 8

    # 1. 从旧 hook handle 取 app classLoader（热重载不会重放 onPackageReady，新实例字段为 null）
    const/4 v0, 0x0

    invoke-interface {p1}, Lio/github/libxposed/api/XposedModuleInterface$HotReloadedParam;->getOldHookHandles()Ljava/util/List;

    move-result-object v1

    invoke-interface {v1}, Ljava/util/List;->isEmpty()Z

    move-result v2

    if-nez v2, :try_handle

    const/4 v2, 0x0

    invoke-interface {v1, v2}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Lio/github/libxposed/api/XposedInterface$HookHandle;

    invoke-interface {v1}, Lio/github/libxposed/api/XposedInterface$HookHandle;->getExecutable()Ljava/lang/reflect/Executable;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/reflect/Executable;->getDeclaringClass()Ljava/lang/Class;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/Class;->getClassLoader()Ljava/lang/ClassLoader;

    move-result-object v0

    :try_handle
    # 2. unhook 全部旧 hooks
    invoke-interface {p1}, Lio/github/libxposed/api/XposedModuleInterface$HotReloadedParam;->getOldHookHandles()Ljava/util/List;

    move-result-object v1

    invoke-interface {v1}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v1

    :loop_unhook
    invoke-interface {v1}, Ljava/util/Iterator;->hasNext()Z

    move-result v2

    if-eqz v2, :done_unhook

    invoke-interface {v1}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Lio/github/libxposed/api/XposedInterface$HookHandle;

    invoke-interface {v2}, Lio/github/libxposed/api/XposedInterface$HookHandle;->unhook()V

    goto :loop_unhook

    :done_unhook
    # 3. fallback：用保存的 mAppClassLoader
    if-nez v0, :have_cl

    iget-object v0, p0, Lcom/hook/qianji/weekstart/MainHook;->mAppClassLoader:Ljava/lang/ClassLoader;

    :have_cl
    # 4. 拿不到 classLoader 就不重装
    if-nez v0, :install

    return-void

    :install
    # 5. 重装 hooks
    invoke-direct {p0, v0}, Lcom/hook/qianji/weekstart/MainHook;->installHooks(Ljava/lang/ClassLoader;)V

    # log(Log.INFO, "QianjiWeekStart", "hot reloaded, hooks reinstalled")
    const/4 v1, 0x4

    const-string v2, "QianjiWeekStart"

    const-string v3, "hot reloaded, hooks reinstalled"

    invoke-virtual {p0, v1, v2, v3}, Lio/github/libxposed/api/XposedInterfaceWrapper;->log(ILjava/lang/String;Ljava/lang/String;)V

    return-void
.end method
