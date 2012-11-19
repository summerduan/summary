/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.security;

import hudson.Launcher;
import hudson.model.AbstractBuild;
import hudson.model.BuildListener;
import hudson.model.Result;
import hudson.model.StringParameterValue;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import net.sf.json.JSONObject;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.lang.math.NumberUtils;

import com.taobao.scm.SpringHelper;
import com.taobao.scm.grid.ProcessCaller;
import com.taobao.scm.services.IRemoteHandler;
import com.taobao.scm.services.err.RemoteAccessException;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-6-12
 */
public interface SecurityCaller extends ProcessCaller {
    String getSvnUrl();

    String getUsername();

    String getPassword();

    String getCodeType();

    String getSvnKey();

    String getThreshold();

    class SecurityCallee extends ProcessCallee<SecurityCaller> {
        private static final String SVNKEY = "${JOB_NAME}";

        private static final String FILENUM_KEY = "SECURITY_FILENUM";

        private static final String BUGNUM_KEY = "SECURITY_BUGNUM";

        public SecurityCallee(SecurityCaller t) {
            super(t);
        }

        @Override
        public boolean process(AbstractBuild<?, ?> build, Launcher launcher, BuildListener listener) throws InterruptedException, IOException {
            Map<String, String> dataMap = new HashMap<String, String>();
            dataMap.put("svnUrl", this.getSvnUrl(build, listener));
            dataMap.put("svnKey", this.getSvnKey(build, listener));
            dataMap.put("username", this.getT().getUsername());
            dataMap.put("password", this.getT().getPassword());
            dataMap.put("codeType", this.getT().getCodeType());

            String filenum_val = null;
            String bugnum_val = null;

            IRemoteHandler remoteHandler = (IRemoteHandler) SpringHelper.getBean("checkHandler");
            try {
                String retnStr = remoteHandler.requestRemote(dataMap);
                JSONObject jo = JSONObject.fromObject(retnStr);
                SecurityResult securityResult = new SecurityResult(build, dataMap, jo);
                SecurityResultAction resultAction = new SecurityResultAction(build, securityResult);
                build.getActions().add(resultAction);
                build.setResult(Result.SUCCESS);

                try {
                    JSONObject summary = jo.getJSONObject("summary");
                    filenum_val = summary.getString("filenum");
                    bugnum_val = summary.getString("bugnum");

                    StringParameterValue[] parameterValues = new StringParameterValue[] {
                            new StringParameterValue(FILENUM_KEY, filenum_val),
                            new StringParameterValue(BUGNUM_KEY, bugnum_val) };

                    this.setCallbackParams(build, parameterValues);
                } catch (Exception e) {
                    // No-Op
                }
            } catch (RemoteAccessException e) {
                listener.getLogger().print(e.fillInStackTrace());
                build.setResult(Result.FAILURE);
            }

            int int_threshold = NumberUtils.toInt(this.getT().getThreshold(), 0);
            int int_bugnum = NumberUtils.toInt(bugnum_val, -1);
            if (int_threshold > 0 && int_bugnum != -1 && int_bugnum > int_threshold) {
                build.setResult(Result.FAILURE);
                listener.getLogger().println("安全检测风险数超出阀值，风险数为：" + int_bugnum + "，阀值为：" + int_threshold + "。");
                return false;
            } else {
                return true;
            }
        }

        private String getSvnUrl(AbstractBuild<?, ?> build, BuildListener listener) throws IOException, InterruptedException {
            String svnUrl = this.getT().getSvnUrl();
            return build.getEnvironment(listener).expand(svnUrl);
        }

        private String getSvnKey(AbstractBuild<?, ?> build, BuildListener listener) throws IOException, InterruptedException {
            String svnKey = this.getT().getSvnKey();
            svnKey = StringUtils.isEmpty(svnKey) ? SecurityCallee.SVNKEY : //
                    new StringBuffer(SecurityCallee.SVNKEY).append("_").append(svnKey).toString();
            return build.getEnvironment(listener).expand(svnKey);
        }
    }
}