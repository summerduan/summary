/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.grid;

import hudson.Extension;
import hudson.model.ParameterDefinition;
import hudson.model.ParameterValue;
import hudson.model.StringParameterValue;
import net.sf.json.JSONObject;

import org.kohsuke.stapler.DataBoundConstructor;
import org.kohsuke.stapler.StaplerRequest;

/**
 * 实现隐藏域，可用于构建时，参数的传递。
 * 
 * @author LingKan <lingkan@taobao.com>
 * @version 2009-9-7
 */
public class HiddenParameterDefinition extends ParameterDefinition {
    private static final long serialVersionUID = 7296806777255584940L;

    private String defaultValue;

    public String getDefaultValue() {
        return defaultValue;
    }

    public void setDefaultValue(String defaultValue) {
        this.defaultValue = defaultValue;
    }

    @DataBoundConstructor
    public HiddenParameterDefinition(String name, String defaultValue, String description) {
        super(name, description);
        this.defaultValue = defaultValue;
    }

    @Extension
    public static class DescriptorImpl extends ParameterDescriptor {
        @Override
        public String getDisplayName() {
            return "Hidden Parameter";
        }
    }

    @Override
    public StringParameterValue getDefaultParameterValue() {
        StringParameterValue v = new StringParameterValue(getName(), defaultValue, getDescription());
        return v;
    }

    public ParameterValue createValue(StaplerRequest req) {
        String[] value = req.getParameterValues(getName());
        if (value == null) {
            return getDefaultParameterValue();
        } else if (value.length != 1) {
            throw new IllegalArgumentException("Illegal number of parameter values for " + getName() + ": " + value.length);
        } else {
            return new StringParameterValue(getName(), value[0], getDescription());
        }
    }

    public ParameterValue createValue(StaplerRequest req, JSONObject jo) {
        StringParameterValue value = req.bindJSON(StringParameterValue.class, jo);
        value.setDescription(getDescription());
        return value;
    }
}
