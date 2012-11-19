/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.security.tabs;

import hudson.model.ModelObject;

import java.io.Serializable;
import java.util.Set;

import net.sf.json.JSONObject;

import com.taobao.scm.analysis.security.SecurityResult;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-4-6
 */
public class SecurityFiles implements ModelObject, Serializable {
    private static final long serialVersionUID = -7075667480390582107L;

    private final JSONObject data;

    public JSONObject getData() {
        return data;
    }

    public SecurityFiles(SecurityResult securityResult) {
        this.data = securityResult.getData();
    }

    @Override
    public String getDisplayName() {
        return "TAB";
    }

    @SuppressWarnings("unchecked")
    public Set getKeySet() {
        return this.data.getJSONObject("filestatistics").keySet();
    }
}
