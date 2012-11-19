/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.security.impl;

import java.util.Map;

import com.taobao.scm.services.IRemoteHandler;
import com.taobao.scm.services.err.RemoteAccessException;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-3-30
 */
public class UpdateHandlerImpl extends IRemoteHandler {
    @Override
    public String requestRemote(Map<String, String> dataMap) throws RemoteAccessException {
        String addrStr = String.format(this.getAddrString(), dataMap.get("id"));
        return this.requestRemote(addrStr);
    }
}
