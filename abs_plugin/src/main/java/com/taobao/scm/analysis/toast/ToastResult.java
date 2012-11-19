/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.toast;

import hudson.model.AbstractBuild;
import hudson.model.ModelObject;

import java.io.Serializable;
import java.util.Date;

import net.sf.json.JSONObject;

import org.apache.commons.lang.StringUtils;
import org.kohsuke.stapler.StaplerRequest;
import org.kohsuke.stapler.StaplerResponse;

import com.taobao.scm.analysis.toast.tabs.FailList;
import com.taobao.scm.analysis.toast.tabs.PassList;
import com.taobao.scm.services.err.RemoteAccessException;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-5-19
 */
public class ToastResult implements ModelObject, Serializable {
    private static final long serialVersionUID = 5565749907057758012L;

    private static final String DISPLAY_NAME = "ToastResult";

    @Override
    public String getDisplayName() {
        return DISPLAY_NAME;
    }

    private boolean invoke;

    private JSONObject retnData;

    public boolean isInvoke() {
        return invoke;
    }

    public void setInvoke(boolean invoke) {
        this.invoke = invoke;
    }

    public JSONObject getRetnData() {
        return retnData;
    }

    public void setRetnData(JSONObject retnData) {
        this.retnData = retnData;
    }

    private boolean success;

    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    private Date callTime;

    public Date getCallTime() {
        return callTime;
    }

    public void setCallTime(Date callTime) {
        this.callTime = callTime;
    }

    private final AbstractBuild<?, ?> owner;

    public AbstractBuild<?, ?> getOwner() {
        return owner;
    }

    public ToastResult(AbstractBuild<?, ?> owner) {
        super();
        this.owner = owner;
    }

    public int getCasePassListSize() {
        JSONObject casePassList = this.retnData.getJSONObject("case_pass_list");
        return casePassList.isNullObject() ? 0 : casePassList.size();
    }

    public int getCaseFailListSize() {
        JSONObject caseFailList = this.retnData.getJSONObject("case_fail_list");
        return caseFailList.isNullObject() ? 0 : caseFailList.size();
    }

    public Object getDynamic(String token, StaplerRequest req, StaplerResponse rsp) throws RemoteAccessException {
        try {
            if (StringUtils.isEmpty(token)) {
                return null;
            }
            if (ToastCallback.URL_NAME.equals(token)) {
                return new ToastCallback(this);
            } else if ("passList".equals(token)) {
                return new PassList(this);
            } else if ("failList".equals(token)) {
                return new FailList(this);
            } else {
                return null;
            }
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
}
