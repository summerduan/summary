/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.toast.multi;

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

import com.taobao.scm.analysis.toast.ToastCaller;
import com.taobao.scm.grid.ProcessScope;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-5-19
 */
public class ToastPublisher extends Recorder implements MatrixAggregatable, ToastCaller {
    // Toast项目标识
    private final String projectId;

    // 测试类型
    private final String type;

    // Detail信息
    private final String detail;

    // 作用域
    private final ProcessScope.Packet processScope;

    public String getProjectId() {
        return projectId;
    }

    public String getType() {
        return type;
    }

    public String getDetail() {
        return detail;
    }

    public ProcessScope.Packet getProcessScope() {
        return processScope;
    }

    @DataBoundConstructor
    public ToastPublisher(String projectId, String type, String build, String[] processScope) {
        this.projectId = projectId;
        this.type = type;
        this.detail = build;
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
            public boolean endBuild() throws InterruptedException, IOException {
                return new ToastCallee(ToastPublisher.this).multiple(build, launcher, listener, processScope);
            }
        };
    }
}
