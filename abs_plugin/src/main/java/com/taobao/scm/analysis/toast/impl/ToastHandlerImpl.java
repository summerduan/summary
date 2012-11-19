/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.toast.impl;

import java.util.Map;

import org.apache.commons.httpclient.NameValuePair;

import com.taobao.scm.services.IRemoteHandler;
import com.taobao.scm.services.err.RemoteAccessException;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-5-20
 */
public class ToastHandlerImpl extends IRemoteHandler {
    @Override
    public String requestRemote(Map<String, String> dataMap) throws RemoteAccessException {
        NameValuePair[] dataParas = new NameValuePair[dataMap.size()];
        int cursor = 0;
        for (String key : dataMap.keySet()) {
            dataParas[cursor++] = new NameValuePair(key, dataMap.get(key));
        }
        return super.requestRemote(this.getAddrString(), dataParas);
    }
}
