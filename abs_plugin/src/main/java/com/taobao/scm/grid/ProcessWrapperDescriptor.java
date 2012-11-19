/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.grid;

import hudson.Extension;
import hudson.model.AbstractProject;
import hudson.model.Descriptor;
import hudson.model.ParameterDefinition;
import hudson.tasks.BuildWrapper;
import hudson.tasks.BuildWrapperDescriptor;
import hudson.tasks.Builder;

import java.util.HashMap;

import net.sf.json.JSONObject;

import org.apache.commons.lang.StringUtils;
import org.kohsuke.stapler.StaplerRequest;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-4-20
 */
@Extension
public final class ProcessWrapperDescriptor extends BuildWrapperDescriptor {
    private final static String CONF_MENU = "\u914d\u7f6e\u6784\u5efa\u53c2\u6570";// 配置构建参数

    public ProcessWrapperDescriptor() {
        super(ProcessWrapper.class);
    }

    @Override
    public String getDisplayName() {
        return CONF_MENU;
    }

    public ProcessType[] getProcessTypes() {
        return ProcessType.values();
    }

    public ProcessStep[] getProcessSteps(String typeCode) {
        return ProcessType.getProcessSteps(typeCode);
    }

    @Override
    public BuildWrapper newInstance(StaplerRequest req, JSONObject formData) throws FormException {
        formData = formData.getJSONObject("processType");
        String processType = formData.isNullObject() ? null : formData.getString("value");
        if (StringUtils.isEmpty(processType)) {
            return new ProcessWrapper(processType, new HashMap<String, ProcessStep.Packet>(0));
        }
        HashMap<String, ProcessStep.Packet> processStep = new HashMap<String, ProcessStep.Packet>(this.getProcessSteps(processType).length);
        for (ProcessStep step : this.getProcessSteps(processType)) {
            ProcessStep.Packet descriptor = new ProcessStep.Packet();
            descriptor.setParameterDefinitions(Descriptor.newInstancesFromHeteroList(req, formData,//
                    step.getCode() + "Parameters", ParameterDefinition.all()));
            descriptor.setPreBuildSteps(Descriptor.newInstancesFromHeteroList(req, formData,//
                    step.getCode() + "PreBuildSteps", Builder.all()));
            descriptor.setPostBuildSteps(Descriptor.newInstancesFromHeteroList(req, formData,//
                    step.getCode() + "PostBuildSteps", Builder.all()));
            processStep.put(step.getCode(), descriptor);
        }
        return new ProcessWrapper(processType, processStep);
    }

    @Override
    public boolean isApplicable(AbstractProject<?, ?> item) {
        return true;
    }
}
