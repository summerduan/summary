/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.toast.def;

import java.util.HashMap;
import java.util.Map;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-6-3
 */
public enum ResultType {
    PASS("0", "通过"),

    FAIL("1", "中断"),

    BLOCK("2", "失败");

    private static final Map<String, ResultType> CONTAINER = new HashMap<String, ResultType>(ResultType.values().length);

    static {
        for (ResultType resultType : ResultType.values()) {
            CONTAINER.put(resultType.code, resultType);
        }
    }

    public static ResultType getInstance(String code) {
        return CONTAINER.get(code);
    }

    private final String code;

    private final String name;

    public String getCode() {
        return code;
    }

    public String getName() {
        return name;
    }

    private ResultType(String code, String name) {
        this.code = code;
        this.name = name;
    }
}
