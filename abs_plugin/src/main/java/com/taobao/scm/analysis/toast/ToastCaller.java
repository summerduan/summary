/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.toast;

import hudson.Launcher;
import hudson.model.AbstractBuild;
import hudson.model.BuildListener;
import hudson.model.Hudson;
import hudson.model.Result;

import java.io.IOException;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import net.sf.json.JSONObject;

import org.apache.commons.lang.StringUtils;
import org.springframework.util.Assert;

import com.taobao.scm.SpringHelper;
import com.taobao.scm.analysis.toast.def.ToastType;
import com.taobao.scm.grid.ProcessCaller;
import com.taobao.scm.services.IRemoteHandler;
import com.taobao.scm.services.ShellHelper;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-6-12
 */
public interface ToastCaller extends ProcessCaller {
    String getProjectId();

    String getType();

    String getDetail();

    class ToastCallee extends ProcessCallee<ToastCaller> {
        // 返回值判断
        private static final String retnSuccess = "success";

        // 数据交换文件名
        private static final String FILENAME = "shell_output.txt";

        // 用户名
        private static final String USER = "ABS";

        public ToastCallee(ToastCaller t) {
            super(t);
        }

        @Override
        public boolean process(AbstractBuild<?, ?> build, Launcher launcher, BuildListener listener) throws InterruptedException, IOException {
            listener.getLogger().println("Toast Start Invoke: " + new Date());
            String filePath = new StringBuffer(build.getRootDir().getAbsolutePath())//
                    .append(System.getProperty("file.separator")).append(FILENAME).toString();
            String urlName = new StringBuffer(ToastResultAction.URL_NAME).append("-").append(System.currentTimeMillis()).toString();
            String callbackUrl = new StringBuffer(StringUtils.defaultString(Hudson.getInstance().getRootUrl()))//
                    .append(build.getUrl()).append(urlName).append("/")//
                    .append(ToastCallback.URL_NAME).append("/?").toString();
            Map<String, String> dataMap = new HashMap<String, String>();
            dataMap.put("project_id", this.getT().getProjectId());
            dataMap.put("type", this.getT().getType());
            dataMap.put("build", this.getDetail(this.getT().getType(), this.getT().getDetail(), filePath));
            dataMap.put("user", USER);
            dataMap.put("callback", callbackUrl);
            IRemoteHandler remoteHandler = (IRemoteHandler) SpringHelper.getBean("toastHandler");
            try {
                String retnStr = remoteHandler.requestRemote(dataMap);
                JSONObject jo = JSONObject.fromObject(retnStr);
                if (retnSuccess.equals(jo.getString("status"))) {
                    ToastResult toastResult = new ToastResult(build);
                    ToastResultAction resultAction = new ToastResultAction(build, toastResult, urlName);
                    build.getActions().add(resultAction);
                    build.setResult(Result.SUCCESS);
                } else {
                    Assert.isTrue(true, jo.getString("result"));
                }
            } catch (Exception e) {
                listener.getLogger().print(e.fillInStackTrace());
                build.setResult(Result.FAILURE);
            }
            listener.getLogger().println("Toast End Invoke: " + new Date());
            return true;
        }

        /**
         * 处理Toast输入参数。
         */
        private String getDetail(String type, String detail, String filePath) {
            ToastType toastType = ToastType.getInstance(type);
            switch (toastType) {
                case UNIT:
                    return detail;
                default:
                    Set<String> rpm = ShellHelper.getShellResult(filePath).get("toast");
                    Assert.notNull(rpm, FILENAME + ": 文件不能为空，且必须写清toast=...键值对");
                    return StringUtils.join(rpm, ",");
            }
        }
    }
}