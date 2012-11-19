/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.security;

import hudson.model.AbstractBuild;
import hudson.model.AbstractProject;
import hudson.model.TaskAction;
import hudson.security.ACL;
import hudson.security.Permission;

import org.kohsuke.stapler.StaplerProxy;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-3-23
 */
public class SecurityResultAction extends TaskAction implements StaplerProxy {
    private static final String DISPLAY_NAME = "SecurityResult";

    private static final String URL_NAME = "securityResult";

    private static final String ICON_FILE_NAME = "/plugin/abs-hudson/images/security-32x32.gif";

    private final SecurityResult securityResult;

    public SecurityResult getSecurityResult() {
        return securityResult;
    }

    private final AbstractBuild<?, ?> build;

    public AbstractBuild<?, ?> getBuild() {
        return build;
    }

    private final String urlName;

    public SecurityResultAction(AbstractBuild<?, ?> build, SecurityResult securityResult) {
        this.securityResult = securityResult;
        this.build = build;
        this.urlName = new StringBuffer(URL_NAME).append("-").append(System.currentTimeMillis()).toString();
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

    @Override
    public Object getTarget() {
        return securityResult;
    }

    @Override
    protected ACL getACL() {
        return this.build.getACL();
    }

    @Override
    protected Permission getPermission() {
        return AbstractProject.BUILD;
    }
}