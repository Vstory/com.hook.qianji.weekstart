#
# L2 回调: qe.c.c(String,int) 静态方法
# getWeekStart() 直接调用它, args[0]=="week" 时强制返回 2(周一)
# 否则 chain.proceed() 走原逻辑
# 静默处理, 不输出日志
#
.class public Lcom/hook/qianji/weekstart/MainHook$QeCCHooker;
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
# Object intercept(Chain chain) -> args[0]=="week" ? Integer.valueOf(2) : chain.proceed()
.method public intercept(Lio/github/libxposed/api/XposedInterface$Chain;)Ljava/lang/Object;
    .registers 5

    # Object arg0 = chain.getArg(0)
    const/4 v0, 0x0

    invoke-interface {p1, v0}, Lio/github/libxposed/api/XposedInterface$Chain;->getArg(I)Ljava/lang/Object;

    move-result-object v0

    # "week".equals(arg0)
    const-string v1, "week"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-nez v1, :cond_week

    # 非 week key → 走原逻辑
    invoke-interface {p1}, Lio/github/libxposed/api/XposedInterface$Chain;->proceed()Ljava/lang/Object;

    move-result-object v0

    return-object v0

    :cond_week
    # key=="week" → 强制返回 2(周一)
    const/4 v0, 0x2

    invoke-static {v0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v0

    return-object v0
.end method
