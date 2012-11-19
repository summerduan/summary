/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.security.impl;

import java.util.Map;

import org.apache.commons.httpclient.NameValuePair;

import com.taobao.scm.services.IRemoteHandler;
import com.taobao.scm.services.err.RemoteAccessException;

/**
 * 远程接口调用实现。
 * 
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-3-29
 */
public class CheckHandlerImpl extends IRemoteHandler {
    public String requestRemote(Map<String, String> dataMap) throws RemoteAccessException {
        NameValuePair[] dataParas = new NameValuePair[] {
                new NameValuePair("svn", dataMap.get("svnUrl")),// SVN地址
                new NameValuePair("key", dataMap.get("svnKey")),// 缓存键
                new NameValuePair("user", dataMap.get("username")),// 用户名
                new NameValuePair("password", dataMap.get("password")),// 密码
                new NameValuePair("type", dataMap.get("codeType")) };// 代码类型
        return super.requestRemote(this.getAddrString(), dataParas);
    }
}
