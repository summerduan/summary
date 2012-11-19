/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.grid;

import hudson.model.ParameterDefinition;
import hudson.tasks.Builder;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-4-19
 */
public enum ProcessStep {
    DEV("priv", "PRIVATE-BUILDING--For DEV", null),

    QA("test", "TEST-BUILDING--For QA", "/plugin/abs-hudson/images/qa.gif"),

    PE("rel", "RELEASE-BUILDING--For PE", "/plugin/abs-hudson/images/pe.gif"),

    MERGE_SOURCE("mergeSource", "MERGE_SOURCE", "/plugin/abs-hudson/images/r1.gif"),

    CONFILCT_RESOLVED("confilctResolved", "CONFILCT_RESOLVED", "/plugin/abs-hudson/images/r2.gif"),

    MERGE_BUILDING("mergeBuilding", "MERGE_BUILDING", "/plugin/abs-hudson/images/r3.gif"),

    RELEASE_BUILDING("releaseBuilding", "RELEASE_BUILDING", "/plugin/abs-hudson/images/r4.gif"),

    PE_UNLOCK("peUnlock", "PE_UNLOCK", "/plugin/abs-hudson/images/r5.gif");

    private static HashMap<String, ProcessStep> CONTAINER = new HashMap<String, ProcessStep>(ProcessStep.values().length);

    static {
        for (ProcessStep processStep : ProcessStep.values()) {
            CONTAINER.put(processStep.getCode(), processStep);
        }
    }

    public static ProcessStep getProcessStep(String code) {
        return CONTAINER.get(code);
    }

    private final String code;

    private final String name;

    private final String iconUrl;

    public String getCode() {
        return code;
    }

    public String getName() {
        return name;
    }

    public String getIconUrl() {
        return iconUrl;
    }

    /**
     * @param code 类型编码，严格命名
     * @param name 类型描述
     * @param iconUrl 结果图标，null 或者 "" 则忽略
     */
    private ProcessStep(String code, String name, String iconUrl) {
        this.code = code;
        this.name = name;
        this.iconUrl = iconUrl;
    }

    public static final class Packet {
        // 参数定义
        private List<ParameterDefinition> parameterDefinitions = new ArrayList<ParameterDefinition>();

        public List<ParameterDefinition> getParameterDefinitions() {
            return parameterDefinitions;
        }

        public void setParameterDefinitions(List<ParameterDefinition> parameterDefinitions) {
            this.parameterDefinitions = parameterDefinitions;
        }

        // 构建前动作
        private List<Builder> preBuildSteps = new ArrayList<Builder>();

        public List<Builder> getPreBuildSteps() {
            return preBuildSteps;
        }

        public void setPreBuildSteps(List<Builder> preBuildSteps) {
            this.preBuildSteps = preBuildSteps;
        }

        // 构建后动作
        private List<Builder> postBuildSteps = new ArrayList<Builder>();

        public List<Builder> getPostBuildSteps() {
            return postBuildSteps;
        }

        public void setPostBuildSteps(List<Builder> postBuildSteps) {
            this.postBuildSteps = postBuildSteps;
        }
    }
}
