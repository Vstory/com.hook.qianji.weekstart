#
# L2 回调: qe.c.c(String,int) 静态方法
# getWeekStart() 直接调用它, key="week" 时强制返回 2(周一)
# 登录/未登录都会经过此方法, 静默处理
#
.class Lcom/hook/qianji/weekstart/HookEntry$2;
.super Lde/robv/android/xposed/XC_MethodHook;


# direct methods
.method constructor <init>(Lcom/hook/qianji/weekstart/HookEntry;)V
    .registers 2

    invoke-direct {p0}, Lde/robv/android/xposed/XC_MethodHook;-><init>()V

    return-void
.end method


# virtual methods
.method protected afterHookedMethod(Lde/robv/android/xposed/XC_MethodHook$MethodHookParam;)V
    .registers 6

    iget-object v0, p1, Lde/robv/android/xposed/XC_MethodHook$MethodHookParam;->args:[Ljava/lang/Object;

    const/4 v1, 0x0

    aget-object v0, v0, v1

    check-cast v0, Ljava/lang/String;

    const-string v1, "week"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-nez v1, :cond_18

    return-void

    :cond_18
    const/4 v0, 0x2

    invoke-static {v0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v0

    iput-object v0, p1, Lde/robv/android/xposed/XC_MethodHook$MethodHookParam;->result:Ljava/lang/Object;

    return-void
.end method
