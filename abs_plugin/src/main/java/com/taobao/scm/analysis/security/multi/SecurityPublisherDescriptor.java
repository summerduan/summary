/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.security.multi;

import hudson.matrix.MatrixProject;
import hudson.model.AbstractProject;
import hudson.tasks.BuildStepDescriptor;
import hudson.tasks.Publisher;

import com.taobao.scm.analysis.security.def.CodeType;
import com.taobao.scm.grid.ProcessScope;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-3-23
 */
// @Extension(ordinal = -1)
public final class SecurityPublisherDescriptor extends BuildStepDescriptor<Publisher> {
    private static final String DISPLAY_NAME = "Security";

    public CodeType[] getCodeTypes() {
        return CodeType.values();
    }

    public ProcessScope getProcessScope() {
        return new ProcessScope();
    }

    public SecurityPublisherDescriptor() {
        super(SecurityPublisher.class);
    }

    @Override
    public String getDisplayName() {
        return DISPLAY_NAME;
    }

    @SuppressWarnings("unchecked")
    @Override
    public boolean isApplicable(Class<? extends AbstractProject> jobType) {
        return MatrixProject.class.isAssignableFrom(jobType);
    }
}
