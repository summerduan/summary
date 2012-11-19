/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm;

import org.springframework.context.ApplicationContext;
import org.springframework.context.support.FileSystemXmlApplicationContext;
import org.springframework.util.ResourceUtils;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-3-29
 */
public class SpringHelper {
    private static final SpringHelper INSTANCE = new SpringHelper();

    public static SpringHelper getInstance() {
        return INSTANCE;
    }

    private SpringHelper() {}

    private ApplicationContext applicationContext;

    public ApplicationContext getApplicationContext() {
        return applicationContext;
    }

    public void setApplicationContext(ApplicationContext applicationContext) {
        this.applicationContext = applicationContext;
    }

    public void initialize() {
        this.applicationContext = new FileSystemXmlApplicationContext(ResourceUtils.CLASSPATH_URL_PREFIX + "conf/applicationContext.xml");
    }

    public static Object getBean(String name) {
        return getInstance().getApplicationContext().getBean(name);
    }
}
