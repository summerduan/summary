/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.toast;

import hudson.model.AbstractBuild;
import hudson.model.AbstractProject;
import hudson.model.TaskAction;
import hudson.security.ACL;
import hudson.security.Permission;

import org.kohsuke.stapler.StaplerProxy;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-5-19
 */
public class ToastResultAction extends TaskAction implements StaplerProxy {
    private static final String DISPLAY_NAME = "ToastResult";

    private static final String ICON_FILE_NAME = "/plugin/abs-hudson/images/toast-24x24.png";

    public static final String URL_NAME = "toastResult";

    private final AbstractBuild<?, ?> build;

    private final ToastResult toastResult;

    public AbstractBuild<?, ?> getBuild() {
        return build;
    }

    public ToastResult getToastResult() {
        return toastResult;
    }

    private final String urlName;

    public ToastResultAction(AbstractBuild<?, ?> build, ToastResult toastResult, String urlName) {
        this.build = build;
        this.toastResult = toastResult;
        this.urlName = urlName;
    }

    @Override
    protected ACL getACL() {
        return this.build.getACL();
    }

    @Override
    protected Permission getPermission() {
        return AbstractProject.BUILD;
    }

    @Override
    public Object getTarget() {
        return this.toastResult;
    }

    @Override
    public String getDisplayName() {
        return DISPLAY_NAME;
    }

    @Override
    public String getIconFileName() {
        return ICON_FILE_NAME;
    }

    @Override
    public String getUrlName() {
        return this.urlName;
    }
}
