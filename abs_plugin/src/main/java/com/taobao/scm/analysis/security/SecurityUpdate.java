/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.security;

import hudson.model.ModelObject;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;

import org.apache.commons.lang.StringEscapeUtils;
import org.kohsuke.stapler.StaplerRequest;
import org.kohsuke.stapler.StaplerResponse;

import com.taobao.scm.SpringHelper;
import com.taobao.scm.services.IRemoteHandler;
import com.taobao.scm.services.err.RemoteAccessException;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-4-9
 */
public class SecurityUpdate implements ModelObject, Serializable {
    private static final long serialVersionUID = -2462914533110027184L;

    private String retnStr;

    public SecurityUpdate(SecurityResult securityResult, String id) throws IOException {
        try {
            IRemoteHandler remoteHandler = (IRemoteHandler) SpringHelper.getBean("updateHandler");
            Map<String, String> dataMap = new HashMap<String, String>(1);
            dataMap.put("id", id);
            this.retnStr = remoteHandler.requestRemote(dataMap);
        } catch (RemoteAccessException e) {
            this.retnStr = "{\"status\": \"failure\", \"msg\": \"" + StringEscapeUtils.escapeHtml(e.getMessage()) + "\"}";
        }

        securityResult.getFalsePositive().add(id);
        securityResult.getOwner().save();
    }

    @Override
    public String getDisplayName() {
        return "UPDATE";
    }

    public void doIndex(final StaplerRequest request, final StaplerResponse response) throws IOException {
        PrintWriter out = response.getWriter();
        out.print(this.retnStr);
        out.close();
    }
}
