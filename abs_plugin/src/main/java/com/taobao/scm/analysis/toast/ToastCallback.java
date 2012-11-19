/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.toast;

import hudson.model.ModelObject;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.Serializable;
import java.util.Date;

import net.sf.json.JSONObject;

import org.kohsuke.stapler.StaplerRequest;
import org.kohsuke.stapler.StaplerResponse;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-5-24
 */
public class ToastCallback implements ModelObject, Serializable {
    private static final long serialVersionUID = 4618097371403926314L;

    public static final String URL_NAME = "callback";

    private static final String CHARSET = "UTF-8";

    private static final String KEY = "json";

    @Override
    public String getDisplayName() {
        return null;
    }

    private final ToastResult toastResult;

    public ToastResult getToastResult() {
        return toastResult;
    }

    public ToastCallback(ToastResult toastResult) {
        this.toastResult = toastResult;
    }

    public void doIndex(final StaplerRequest request, final StaplerResponse response) throws IOException {
        request.setCharacterEncoding(CHARSET);

        PrintWriter out = response.getWriter();
        JSONObject retnJson = new JSONObject();
        try {
            String retnStr = request.getParameter(KEY);
            JSONObject backData = JSONObject.fromObject(retnStr);
            this.toastResult.setInvoke(true);
            this.toastResult.setRetnData(backData);
            this.toastResult.setSuccess(true);

            this.toastResult.getOwner().save();

            retnJson.put("status", true);
        } catch (Exception e) {
            this.toastResult.setInvoke(false);
            this.toastResult.setSuccess(false);

            retnJson.put("status", false);
            retnJson.put("result", e.getMessage());
        } finally {
            this.toastResult.setCallTime(new Date());
        }

        out.print(retnJson.toString());
        out.flush();
        out.close();
    }
}
