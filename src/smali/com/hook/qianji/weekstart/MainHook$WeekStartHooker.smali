#
# L1 回调: qe.c.getWeekStart() 无参静态方法
# 最直接的聚合点, 强制返回 2(周一)
# 静默处理（api102 Hooker 无 log 通道，日志在 MainHook 生命周期方法输出）
#
.class public Lcom/hook/qianji/weekstart/MainHook$WeekStartHooker;
.super Ljava/lang/Object;

# interfaces
.implements Lio/github/libxposed/api/XposedInterface$Hooker;


# direct methods
.method public constructor <init>()V
    .registers 1

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
# Object intercept(Chain chain) -> Integer.valueOf(2)
.method public intercept(Lio/github/libxposed/api/XposedInterface$Chain;)Ljava/lang/Object;
    .registers 2

    const/4 v0, 0x2

    invoke-static {v0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v0

    return-object v0
.end method
