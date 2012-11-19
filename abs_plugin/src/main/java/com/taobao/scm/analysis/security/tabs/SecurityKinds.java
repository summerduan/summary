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

import net.sf.json.JSONObject;

import com.taobao.scm.SpringHelper;
import com.taobao.scm.services.IRemoteHandler;
import com.taobao.scm.services.err.RemoteAccessException;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-5-5
 */
public class SecurityKinds implements ModelObject, Serializable {
    private static final long serialVersionUID = 2990341074949282024L;

    @Override
    public String getDisplayName() {
        return "TAB";
    }

    private final JSONObject jo;

    public SecurityKinds() throws RemoteAccessException {
        IRemoteHandler remoteHandler = (IRemoteHandler) SpringHelper.getBean("bugtypeHandler");
        String retnStr = remoteHandler.requestRemote(null);
        this.jo = JSONObject.fromObject(retnStr);
    }

    public JSONObject getSecurityKinds() throws RemoteAccessException {
        return this.jo;
    }
}
