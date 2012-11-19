/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.toast;

import hudson.matrix.MatrixProject;
import hudson.model.AbstractProject;
import hudson.tasks.BuildStepDescriptor;
import hudson.tasks.Builder;

import com.taobao.scm.analysis.toast.def.ToastType;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-5-19
 */
// @Extension(ordinal = -2)
public final class ToastPublisherDescriptor extends BuildStepDescriptor<Builder> {
    private static final String DISPLAY_NAME = "Toast";

    public ToastType[] getToastTypes() {
        return ToastType.values();
    }

    public ToastPublisherDescriptor() {
        super(ToastPublisher.class);
    }

    @Override
    public String getDisplayName() {
        return DISPLAY_NAME;
    }

    @SuppressWarnings("unchecked")
    @Override
    public boolean isApplicable(Class<? extends AbstractProject> jobType) {
        return !MatrixProject.class.isAssignableFrom(jobType);
    }
}
