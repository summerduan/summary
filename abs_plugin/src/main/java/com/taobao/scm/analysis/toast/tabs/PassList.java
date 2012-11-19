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
public class PassList implements ModelObject, Serializable {
    private static final long serialVersionUID = -4816464943384507371L;

    @Override
    public String getDisplayName() {
        return "TAB";
    }

    private final JSONObject passList;

    public PassList(ToastResult toastResult) {
        super();
        JSONObject casePassList = toastResult.getRetnData().getJSONObject("case_pass_list");
        this.passList = casePassList.isNullObject() ? new JSONObject() : casePassList;
    }

    public JSONObject getCasePassList() {
        return this.passList;
    }

    public String getTestType(String code) {
        ResultType resultType = ResultType.getInstance(code);
        return resultType == null ? "未知" : resultType.getName();
    }
}
