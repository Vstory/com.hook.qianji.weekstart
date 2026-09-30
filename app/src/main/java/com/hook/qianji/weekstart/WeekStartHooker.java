package com.hook.qianji.weekstart;

import io.github.libxposed.api.XposedInterface;

/**
 * L1 回调: qe.c.getWeekStart() 无参静态方法
 * 最直接的聚合点, 强制返回 2(周一)
 */
public class WeekStartHooker implements XposedInterface.Hooker {
    @Override
    public Object intercept(XposedInterface.Chain chain) {
        return 2; // Integer.valueOf(2)
    }
}
