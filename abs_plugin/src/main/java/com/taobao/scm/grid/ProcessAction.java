/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.grid;

import hudson.model.AbstractProject;
import hudson.model.Action;
import hudson.model.Cause;
import hudson.model.Hudson;
import hudson.model.Item;
import hudson.model.ParameterDefinition;
import hudson.model.ParameterValue;
import hudson.model.ParametersDefinitionProperty;
import hudson.model.Result;
import hudson.model.Run;
import hudson.model.StringParameterValue;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;

import javax.servlet.ServletException;

import net.sf.json.JSONArray;
import net.sf.json.JSONObject;

import org.apache.commons.lang.StringUtils;
import org.kohsuke.stapler.StaplerRequest;
import org.kohsuke.stapler.StaplerResponse;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-4-19
 */
public class ProcessAction implements Action {
    private final static String JOB_MENU = "\u81ea\u52a8\u6784\u5efa";// 自动构建

    private final static String URL = "url";

    private final AbstractProject<?, ?> project;

    public AbstractProject<?, ?> getProject() {
        return project;
    }

    private final ProcessWrapper processWrapper;

    public ProcessWrapper getProcessWrapper() {
        return processWrapper;
    }

    public ProcessAction(AbstractProject<?, ?> project, ProcessWrapper processWrapper) {
        this.project = project;
        this.processWrapper = processWrapper;
    }

    /**
     * {@inheritDoc}
     */
    public String getDisplayName() {
        return JOB_MENU;
    }

    /**
     * {@inheritDoc}
     */
    public String getIconFileName() {
        return "package.gif";
    }

    /**
     * {@inheritDoc}
     */
    public String getUrlName() {
        return "process";
    }

    public ProcessStep[] getProcessSteps() {
        return ProcessType.getProcessSteps(this.getProcessWrapper().getProcessType());
    }

    public HashMap<String, ProcessStep.Packet> getProcessStep() {
        return this.processWrapper.getProcessStep();
    }

    // 分构建类型，根据键获取自定义值。
    private ParameterDefinition getParameterDefinition(String phase, String name) {
        ProcessStep.Packet descriptor = this.processWrapper.getProcessStep().get(phase);
        if (descriptor == null) {
            return null;
        }
        List<ParameterDefinition> parameterDefinitions = descriptor.getParameterDefinitions();
        for (ParameterDefinition pd : parameterDefinitions) {
            if (pd.getName().equals(name)) {
                return pd;
            }
        }
        return null;
    }

    /**
     * @return 缺省构建参数。
     */
    private ArrayList<ParameterValue> getParamValues() {
        ArrayList<ParameterValue> paramValues = new ArrayList<ParameterValue>();
        ParametersDefinitionProperty paramDefProp = project.getProperty(ParametersDefinitionProperty.class);
        if (paramDefProp != null) {
            // 自定义参数是否有缺省值，有则加入参数集合。
            List<ParameterDefinition> parameterDefinitions = paramDefProp.getParameterDefinitions();
            for (ParameterDefinition paramDefinition : parameterDefinitions) {
                ParameterValue defaultValue = paramDefinition.getDefaultParameterValue();
                if (defaultValue != null) {
                    paramValues.add(defaultValue);
                }
            }
        }
        return paramValues;
    }

    /**
     * 编译完成后的处理方式。
     */
    private void handlerResult(StaplerRequest req, StaplerResponse resp, boolean success, ParameterValue url) throws IOException {
        // 构建完成后，如果在全局参数中存在“url”参数，则实施URL跳转，并Alert参数的备注信息。
        if (success && url != null && url instanceof StringParameterValue) {
            String defaultValue = ((StringParameterValue) url).value;
            defaultValue = StringUtils.isEmpty(defaultValue) ? "./" : defaultValue;
            String description = ((StringParameterValue) url).getDescription();

            resp.setContentType("text/html;charset=UTF-8");
            resp.setCharacterEncoding("UTF-8");
            PrintWriter out = resp.getWriter();
            out.println("<SCRIPT language=\"JavaScript\" type=\"text/javascript\">");
            out.println("<!--");
            if (description != null && description.length() > 0) {
                out.println("window.alert('" + description.replace("\'", "\\'") + "');");
            }
            out.println("window.document.location = '" + resp.encodeURL(defaultValue.replace("\'", "\\'")) + "';");
            out.println("//-->");
            out.println("</SCRIPT>");
            out.close();
        } else {
            // 返回任务页
            resp.sendRedirect(project.getAbsoluteUrl());
        }
    }

    /**
     * 自动构建提交动作。
     */
    public void doSubmit(StaplerRequest req, StaplerResponse resp) throws IOException, ServletException, InterruptedException, ExecutionException {
        project.checkPermission(Item.BUILD);

        JSONObject formData = req.getSubmittedForm();

        JSONObject phaseData = formData.getJSONObject("phase");

        if (phaseData.isNullObject()) {
            resp.sendRedirect(project.getAbsoluteUrl());
            return;
        }

        ArrayList<ParameterValue> paramValues = this.getParamValues();

        String type = formData.getString("type");

        String phase = phaseData.getString("value");

        JSONArray paras = JSONArray.fromObject(phaseData.get("parameter"));

        ParameterValue url = null;

        for (Object obj : paras) {
            JSONObject jo = (JSONObject) obj;

            if (jo.isNullObject()) {
                continue;
            }

            String name = jo.getString("name");

            ParameterDefinition def = getParameterDefinition(phase, name);

            if (def == null) {
                throw new IllegalArgumentException("No such parameter definition: " + name);
            }

            ParameterValue val = def.createValue(req, jo);

            if (URL.equalsIgnoreCase(val.getName())) {
                url = val;
            } else {
                paramValues.add(val);
            }
        }

        ProcessWrapper.ProcessBuildAction processBuildAction = new ProcessWrapper.ProcessBuildAction(
                type,
                phase,
                Hudson.getAuthentication().getName(),
                paramValues);

        // 捕获构建结果
        Future<?> future = project.scheduleBuild2(0, new Cause.UserCause(), processBuildAction);

        if (future == null) {
            resp.sendRedirect(project.getAbsoluteUrl());
            return;
        }

        Run<?, ?> build = (Run<?, ?>) future.get();

        boolean success = Result.SUCCESS == build.getResult();
        processBuildAction.setSuccess(success);

        this.handlerResult(req, resp, success, url);
    }
}
