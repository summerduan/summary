/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.toast.tabs;

import hudson.model.ModelObject;

import java.io.Serializable;

import net.sf.json.JSONObject;

import com.taobao.scm.analysis.toast.ToastResult;
import com.taobao.scm.analysis.toast.def.ResultType;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-6-3
 */
public class FailList implements ModelObject, Serializable {
    private static final long serialVersionUID = 1937007272861357483L;

    @Override
    public String getDisplayName() {
        return "TAB";
    }

    private final JSONObject failList;

    public FailList(ToastResult toastResult) {
        super();
        JSONObject caseFailList = toastResult.getRetnData().getJSONObject("case_fail_list");
        this.failList = caseFailList.isNullObject() ? new JSONObject() : caseFailList;
    }

    public JSONObject getCaseFailList() {
        return this.failList;
    }

    public String getTestType(String code) {
        ResultType resultType = ResultType.getInstance(code);
        return resultType == null ? "未知" : resultType.getName();
    }
}
