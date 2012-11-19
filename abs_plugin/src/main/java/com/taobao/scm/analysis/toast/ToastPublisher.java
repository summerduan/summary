/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.toast;

import hudson.Launcher;
import hudson.model.AbstractBuild;
import hudson.model.BooleanParameterValue;
import hudson.model.BuildListener;
import hudson.model.ParametersAction;
import hudson.tasks.BuildStepMonitor;
import hudson.tasks.Builder;

import java.io.IOException;

import org.kohsuke.stapler.DataBoundConstructor;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-5-19
 */
public class ToastPublisher extends Builder implements ToastCaller {
    private static final String TOAST_SKIP = "TOAST_SKIP";

    // Toast项目标识
    private final String projectId;

    // 测试类型
    private final String type;

    // Detail信息
    private final String detail;

    public String getProjectId() {
        return projectId;
    }

    public String getType() {
        return type;
    }

    public String getDetail() {
        return detail;
    }

    @DataBoundConstructor
    public ToastPublisher(String projectId, String type, String build) {
        this.projectId = projectId;
        this.type = type;
        this.detail = build;
    }

    @Override
    public BuildStepMonitor getRequiredMonitorService() {
        return BuildStepMonitor.STEP;
    }

    @Override
    public boolean perform(AbstractBuild<?, ?> build, Launcher launcher, BuildListener listener) throws InterruptedException, IOException {
        ParametersAction parameters = build.getAction(ParametersAction.class);
        if (parameters != null && parameters.getParameter(TOAST_SKIP) instanceof BooleanParameterValue) {
            BooleanParameterValue toastSkip = (BooleanParameterValue) parameters.getParameter(TOAST_SKIP);
            if (toastSkip.value) {
                return true;
            }
        }
        return new ToastCallee(this).process(build, launcher, listener);
    }
}
