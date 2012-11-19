/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.security;

import hudson.model.AbstractBuild;
import hudson.model.ModelObject;

import java.io.Serializable;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import net.sf.json.JSONObject;

import org.apache.commons.lang.StringUtils;
import org.kohsuke.stapler.StaplerRequest;
import org.kohsuke.stapler.StaplerResponse;

import com.taobao.scm.analysis.security.tabs.SecurityFiles;
import com.taobao.scm.analysis.security.tabs.SecurityKinds;
import com.taobao.scm.analysis.security.tabs.SecurityTypes;
import com.taobao.scm.services.err.RemoteAccessException;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-3-23
 */
public class SecurityResult implements ModelObject, Serializable {
    private static final long serialVersionUID = 2768250056765266658L;

    private static final String DISPLAY_NAME = "SecurityResult";

    private static final String SUCCESS = "success";

    private final AbstractBuild<?, ?> owner;

    private final JSONObject data;

    private final Map<String, String> config;

    public Map<String, String> getConfig() {
        return config;
    }

    private Set<String> falsePositive = new HashSet<String>();

    public Set<String> getFalsePositive() {
        return falsePositive;
    }

    public void setFalsePositive(Set<String> falsePositive) {
        this.falsePositive = falsePositive;
    }

    public JSONObject getData() {
        return data;
    }

    public SecurityResult(AbstractBuild<?, ?> owner, Map<String, String> config, JSONObject data) {
        this.owner = owner;
        this.config = config;
        this.data = data;
    }

    @Override
    public String getDisplayName() {
        return DISPLAY_NAME;
    }

    public AbstractBuild<?, ?> getOwner() {
        return owner;
    }

    public Object getDynamic(String token, StaplerRequest req, StaplerResponse rsp) throws RemoteAccessException {
        try {
            if (StringUtils.isEmpty(token)) {
                return null;
            }
            if (token.startsWith("source:")) {
                return new SecurityDetail(this, token.substring(7, token.length()));
            } else if (token.startsWith("update:")) {
                return new SecurityUpdate(this, token.substring(7, token.length()));
            } else if ("tab.types".equals(token)) {
                return new SecurityTypes(this);
            } else if ("tab.files".equals(token)) {
                return new SecurityFiles(this);
            } else if ("tab.kinds".equals(token)) {
                return new SecurityKinds();
            } else {
                return null;
            }
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    public boolean hasResults() {
        JSONObject jo = data.getJSONObject("bugtypestatistics");
        return !jo.isNullObject() && jo.size() > 0;
    }

    public boolean isSuccess() {
        return SUCCESS.equals(data.getString("status"));
    }
}
