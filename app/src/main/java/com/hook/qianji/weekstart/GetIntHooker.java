package com.hook.qianji.weekstart;

import io.github.libxposed.api.XposedInterface;

/**
 * L3 回调: va.d.getInt(String,int) - MMKV 底层封装
 * args[0]=="week" 或 args[0]=="apiconfu_week" 时强制返回 2(周一)
 * 否则 chain.proceed() 走原逻辑
 */
public class GetIntHooker implements XposedInterface.Hooker {
    @Override
    public Object intercept(XposedInterface.Chain chain) {
        Object arg0 = chain.getArg(0);
        if ("week".equals(arg0) || "apiconfu_week".equals(arg0)) {
            return 2; // Integer.valueOf(2)
        }
        return chain.proceed();
    }
}
