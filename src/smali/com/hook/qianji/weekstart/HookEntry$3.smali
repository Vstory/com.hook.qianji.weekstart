#
# L1 回调: qe.c.getWeekStart() 无参静态方法
# 最直接的聚合点, 强制返回 2(周一)
# 保留单条日志便于确认 hook 生效
#
.class Lcom/hook/qianji/weekstart/HookEntry$3;
.super Lde/robv/android/xposed/XC_MethodHook;


# direct methods
.method constructor <init>(Lcom/hook/qianji/weekstart/HookEntry;)V
    .registers 2

    invoke-direct {p0}, Lde/robv/android/xposed/XC_MethodHook;-><init>()V

    return-void
.end method


# virtual methods
.method protected afterHookedMethod(Lde/robv/android/xposed/XC_MethodHook$MethodHookParam;)V
    .registers 3

    const-string v0, "钱迹强制周一 v1.0.15: ★拦截getWeekStart→周一(2)"

    invoke-static {v0}, Lde/robv/android/xposed/XposedBridge;->log(Ljava/lang/String;)V

    const/4 v0, 0x2

    invoke-static {v0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v0

    iput-object v0, p1, Lde/robv/android/xposed/XC_MethodHook$MethodHookParam;->result:Ljava/lang/Object;

    return-void
.end method
