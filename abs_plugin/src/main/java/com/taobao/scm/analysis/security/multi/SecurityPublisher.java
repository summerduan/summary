/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.security.multi;

import hudson.Launcher;
import hudson.matrix.MatrixAggregatable;
import hudson.matrix.MatrixAggregator;
import hudson.matrix.MatrixBuild;
import hudson.model.AbstractBuild;
import hudson.model.BuildListener;
import hudson.tasks.BuildStepMonitor;
import hudson.tasks.Recorder;

import java.io.IOException;

import org.kohsuke.stapler.DataBoundConstructor;

import com.taobao.scm.analysis.security.SecurityCaller;
import com.taobao.scm.grid.ProcessScope;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-3-23
 */
public class SecurityPublisher extends Recorder implements MatrixAggregatable, SecurityCaller {
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

    // 作用域
    private final ProcessScope.Packet processScope;

    public ProcessScope.Packet getProcessScope() {
        return processScope;
    }

    @DataBoundConstructor
    public SecurityPublisher(String svnUrl, String username, String password, String codeType, String svnKey, String threshold, String[] processScope) {
        this.svnUrl = svnUrl;
        this.username = username;
        this.password = password;
        this.codeType = codeType;
        this.svnKey = svnKey;
        this.threshold = threshold;
        this.processScope = new ProcessScope.Packet(processScope);
    }

    @Override
    public BuildStepMonitor getRequiredMonitorService() {
        return BuildStepMonitor.STEP;
    }

    @Override
    public boolean perform(AbstractBuild<?, ?> build, Launcher launcher, BuildListener listener) throws InterruptedException, IOException {
        return true;
    }

    @Override
    public MatrixAggregator createAggregator(MatrixBuild build, Launcher launcher, BuildListener listener) {
        return new MatrixAggregator(build, launcher, listener) {
            @Override
            public boolean startBuild() throws InterruptedException, IOException {
                return new SecurityCallee(SecurityPublisher.this).multiple(build, launcher, listener, processScope);
            }
        };
    }
}
