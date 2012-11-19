/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.security;

import hudson.Launcher;
import hudson.model.AbstractBuild;
import hudson.model.BuildListener;
import hudson.tasks.BuildStepMonitor;
import hudson.tasks.Builder;

import java.io.IOException;

import org.kohsuke.stapler.DataBoundConstructor;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-3-23
 */
public class SecurityPublisher extends Builder implements SecurityCaller {
    /**
     * SVN地址
     */
    private final String svnUrl;

    /**
     * SVN用户名
     */
    private final String username;

    /**
     * SVN密码
     */
    private final String password;

    /**
     * 代码类型
     */
    private final String codeType;

    /**
     * 工程标识键
     */
    private final String svnKey;

    /**
     * 检测风险数数阀值
     */
    private final String threshold;

    public String getSvnUrl() {
        return svnUrl;
    }

    public String getUsername() {
        return username;
    }

    public String getPassword() {
        return password;
    }

    public String getCodeType() {
        return codeType;
    }

    public String getSvnKey() {
        return svnKey;
    }

    public String getThreshold() {
        return threshold;
    }

    @DataBoundConstructor
    public SecurityPublisher(String svnUrl, String username, String password, String codeType, String svnKey, String threshold) {
        this.svnUrl = svnUrl;
        this.username = username;
        this.password = password;
        this.codeType = codeType;
        this.svnKey = svnKey;
        this.threshold = threshold;
    }

    @Override
    public BuildStepMonitor getRequiredMonitorService() {
        return BuildStepMonitor.STEP;
    }

    @Override
    public boolean perform(AbstractBuild<?, ?> build, Launcher launcher, BuildListener listener) throws InterruptedException, IOException {
        return new SecurityCallee(this).process(build, launcher, listener);
    }
}
