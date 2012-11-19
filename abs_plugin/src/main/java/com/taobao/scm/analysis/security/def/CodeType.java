/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.security.def;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-4-21
 */
public enum CodeType {
    WEB("web", "WEB"),

    C("c", "C"),

    PHP("php", "PHP");

    private final String code;

    private final String name;

    public String getCode() {
        return code;
    }

    public String getName() {
        return name;
    }

    private CodeType(String code, String name) {
        this.code = code;
        this.name = name;
    }
}
