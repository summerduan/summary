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
 * @version 2010-5-19
 */
public enum ToastType {
    UNIT("1", "Unit Test"),

    BVT("2", "Bvt Test"),

    REGRESSION("3", "Regression Test"),

    PERFORMANCE("4", "Performance Test");

    private static final Map<String, ToastType> CONTAINER = new HashMap<String, ToastType>(ToastType.values().length);

    static {
        for (ToastType toastType : ToastType.values()) {
            CONTAINER.put(toastType.code, toastType);
        }
    }

    public static ToastType getInstance(String code) {
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

    private ToastType(String code, String name) {
        this.code = code;
        this.name = name;
    }
}
