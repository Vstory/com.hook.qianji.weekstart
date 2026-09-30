package com.hook.qianji.weekstart;

import io.github.libxposed.api.XposedInterface;

/**
 * L2 回调: qe.c.c(String,int) 静态方法
 * getWeekStart() 直接调用它, args[0]=="week" 时强制返回 2(周一)
 * 否则 chain.proceed() 走原逻辑
 */
public class QeCCHooker implements XposedInterface.Hooker {
    @Override
    public Object intercept(XposedInterface.Chain chain) {
        Object arg0 = chain.getArg(0);
        if ("week".equals(arg0)) {
            return 2; // Integer.valueOf(2)
        }
        return chain.proceed();
    }
}
