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
import hudson.model.BuildListener;
import hudson.model.ParameterValue;

import java.io.IOException;
import java.util.List;

import com.taobao.scm.grid.ProcessWrapper.ProcessBuildAction;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-6-12
 */
public interface ProcessCaller {
    abstract class ProcessCallee<T extends ProcessCaller> {
        private final T t;

        public T getT() {
            return t;
        }

        public ProcessCallee(T t) {
            super();
            this.t = t;
        }

        /**
         * 设置回调的参数。
         */
        protected void setCallbackParams(AbstractBuild<?, ?> build, ParameterValue... parameterValues) {
            try {
                // 参数队列
                List<ParameterValue> ls = ProcessListener.getParamsList(build);
                // 添加运行参数
                for (ParameterValue parameterValue : parameterValues) {
                    ls.add(parameterValue);
                }
            } catch (IllegalArgumentException e) {
                e.printStackTrace();
            } catch (IllegalAccessException e) {
                e.printStackTrace();
            }
        }

        /**
         * 是否跳过编译阶段。
         */
        private boolean skip(AbstractBuild<?, ?> build, ProcessScope.Packet processScope) {
            final ProcessBuildAction processBuildAction = build.getAction(ProcessBuildAction.class);
            return processBuildAction != null && processScope != null //
                    && !processScope.contains(processBuildAction.getType(), processBuildAction.getPhase());
        }

        /**
         * 多节点业务处理过程。
         */
        public boolean multiple(AbstractBuild<?, ?> build, Launcher launcher, BuildListener listener, ProcessScope.Packet processScope)
                throws InterruptedException, IOException {
            if (this.skip(build, processScope)) {
                return true;
            }
            return this.process(build, launcher, listener);
        }

        /**
         * 单节点业务处理过程。
         */
        public abstract boolean process(AbstractBuild<?, ?> build, Launcher launcher, BuildListener listener)
                throws InterruptedException, IOException;
    }
}
