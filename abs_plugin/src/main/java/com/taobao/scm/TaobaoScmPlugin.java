/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm;

import hudson.Plugin;

import org.tmatesoft.svn.core.internal.io.dav.DAVRepositoryFactory;

/**
 * 系统启动。
 * 
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-3-29
 */
public class TaobaoScmPlugin extends Plugin {
    @Override
    public void start() throws Exception {
        // 初始化Spring容器。
        SpringHelper.getInstance().initialize();
        DAVRepositoryFactory.setup();
    }
}
