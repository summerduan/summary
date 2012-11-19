/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.grid;

import hudson.Launcher;
import hudson.model.AbstractBuild;
import hudson.model.AbstractProject;
import hudson.model.Action;
import hudson.model.BuildBadgeAction;
import hudson.model.BuildListener;
import hudson.model.ParameterValue;
import hudson.model.ParametersAction;
import hudson.tasks.BuildStep;
import hudson.tasks.BuildWrapper;
import hudson.tasks.Builder;

import java.io.IOException;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;

/**
 * 实现构建包装接口，依当前业务，通过此实现，把构建过程拆分为：开发、测试和发布三个过程。
 * 
 * @author LingKan <lingkan@taobao.com>
 * @version 2009-8-31
 */
@SuppressWarnings("unchecked")
public class ProcessWrapper extends BuildWrapper {
    protected final String processType;

    public String getProcessType() {
        return processType == null ? ProcessType.PROCESS.getCode() : processType;
    }

    protected final HashMap<String, ProcessStep.Packet> processStep;

    public HashMap<String, ProcessStep.Packet> getProcessStep() {
        return processStep;
    }

    public ProcessWrapper(String processType, HashMap<String, ProcessStep.Packet> processStep) {
        this.processType = processType;
        this.processStep = processStep;
    }

    @Override
    public Collection<? extends Action> getProjectActions(AbstractProject job) {
        Action action = new ProcessAction(job, this);
        return Collections.singletonList(action);
    }

    private boolean executeBuildSteps(List<Builder> buildSteps, AbstractBuild build, Launcher launcher, BuildListener listener) throws InterruptedException,
            IOException {
        boolean shouldContinue = true;
        // execute prebuild steps, stop processing if indicated
        for (BuildStep buildStep : buildSteps) {
            if (!shouldContinue) {
                break;
            }
            shouldContinue = buildStep.prebuild(build, listener);
        }
        // execute build step, stop processing if indicated
        for (BuildStep buildStep : buildSteps) {
            if (!shouldContinue) {
                break;
            }
            shouldContinue = buildStep.perform(build, launcher, listener);
        }
        return shouldContinue;
    }

    @Override
    public Environment setUp(AbstractBuild build, final Launcher launcher, BuildListener listener) throws IOException, InterruptedException {
        final ProcessBuildAction processBuildAction = build.getAction(ProcessBuildAction.class);

        if (processBuildAction == null) {
            return new Environment() {};
        }

        String phase = processBuildAction.getPhase();

        String errMsg = "Could not execute pre-build steps";

        final ProcessStep.Packet descriptor = this.processStep.get(phase);

        if (descriptor != null) {
            if (!executeBuildSteps(descriptor.getPreBuildSteps(), build, launcher, listener)) {
                throw new IOException(errMsg);
            }
            return new Environment() {
                @Override
                public boolean tearDown(AbstractBuild build, BuildListener listener) throws IOException, InterruptedException {
                    build.keepLog();
                    return executeBuildSteps(descriptor.getPostBuildSteps(), build, launcher, listener);
                }
            };
        } else {
            return new Environment() {};
        }
    }

    /**
     * 实现“BuildBadgeAction”接口，可以存储当次构建的状态值，并持久化。
     */
    public static class ProcessBuildAction extends ParametersAction implements BuildBadgeAction {
        private boolean success;

        public boolean isSuccess() {
            return success;
        }

        public void setSuccess(boolean success) {
            this.success = success;
        }

        private final String type;

        public String getType() {
            return type;
        }

        private final String phase;

        public String getPhase() {
            return phase;
        }

        private final String caller;

        public String getCaller() {
            return caller;
        }

        public String getIconUrl() {
            ProcessStep processStep = ProcessStep.getProcessStep(this.phase);
            return processStep != null && processStep.getIconUrl() != null ? processStep.getIconUrl() : "";
        }

        public ProcessBuildAction(String type, String phase, String caller, List<ParameterValue> parameters) {
            super(parameters);
            this.type = type;
            this.phase = phase;
            this.caller = caller;
        }

        public ProcessBuildAction(String type, String phase, String caller, ParameterValue... parameters) {
            super(parameters);
            this.type = type;
            this.phase = phase;
            this.caller = caller;
        }
    }
}
