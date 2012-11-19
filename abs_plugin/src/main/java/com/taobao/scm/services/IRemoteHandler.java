/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.services;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.Map;

import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.HttpStatus;
import org.apache.commons.httpclient.NameValuePair;
import org.apache.commons.httpclient.methods.PostMethod;
import org.apache.commons.lang.StringUtils;
import org.springframework.util.Assert;

import com.taobao.scm.services.err.RemoteAccessException;

/**
 * 远程接口调用。
 * 
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-3-29
 */
public abstract class IRemoteHandler {
    private String charset = "UTF-8";

    public String getCharset() {
        return charset;
    }

    public void setCharset(String charset) {
        this.charset = charset;
    }

    private String addrString;

    public String getAddrString() {
        return addrString;
    }

    public void setAddrString(String addrString) {
        this.addrString = addrString;
    }

    /**
     * 远程接口调用方法。
     * 
     * @param addrString 远程调用地址
     * @return 返回字符串
     * @throws RemoteAccessException 远程调用异常
     */
    protected String requestRemote(String addrString) throws RemoteAccessException {
        return this.requestRemote(addrString, null);
    }

    /**
     * 远程接口调用方法。
     * 
     * @param addrString 远程调用地址
     * @param dataParas 参数
     * @return 返回字符串
     * @throws RemoteAccessException 远程调用异常
     */
    protected String requestRemote(String addrString, NameValuePair[] dataParas) throws RemoteAccessException {
        if (StringUtils.isEmpty(addrString)) {
            throw new IllegalArgumentException("参数[addString]不能为空!");
        }
        // 构造HttpClient的实例
        HttpClient httpClient = new HttpClient();
        // 设置连接超时时间
        httpClient.getHttpConnectionManager().getParams().setConnectionTimeout(5000);
        // 创建POST方法的实例
        PostMethod postMethod = new PostMethod(addrString);
        postMethod.getParams().setContentCharset(this.getCharset());

        if (dataParas != null) {
            postMethod.setRequestBody(dataParas);
        }

        try {
            // 执行postMethod
            int statusCode = httpClient.executeMethod(postMethod);
            Assert.isTrue(statusCode == HttpStatus.SC_OK || statusCode == HttpStatus.SC_CREATED, "[ABS] 远程地址调用返回：" + statusCode);

            return this.convertStreamToString(postMethod.getResponseBodyAsStream());
        } catch (Exception e) {
            try {
                String lineSepa = System.getProperty("line.separator");
                StringBuffer strb = new StringBuffer();
                strb.append(e.getLocalizedMessage());
                strb.append(lineSepa);
                strb.append("远程地址连接异常，请求的地址为：");
                strb.append(postMethod.getURI());
                strb.append(lineSepa);
                NameValuePair[] nv = postMethod.getParameters();
                int count = nv.length;
                for (int i = 0; i < count; i++) {
                    if ("password".equals(nv[i].getName())) {
                        continue;
                    }
                    strb.append(nv[i].getName());
                    strb.append(": ");
                    strb.append(nv[i].getValue());
                    strb.append(lineSepa);
                }
                throw new RemoteAccessException(strb.toString(), e);
            } catch (IOException ex) {
                throw new RemoteAccessException("远程地址连接异常", ex);
            }
        } finally {
            // 释放连接
            postMethod.releaseConnection();
        }
    }

    /**
     * 输换输入流为字符串
     * 
     * @param is 输入流
     * @return 字符串
     */
    private String convertStreamToString(InputStream is) throws IOException {
        BufferedReader reader = new BufferedReader(new InputStreamReader(is, this.getCharset()));
        StringBuilder sb = new StringBuilder();

        String line = null;
        try {
            while ((line = reader.readLine()) != null) {
                sb.append(line + "\n");
            }
        } finally {
            is.close();
        }
        return sb.toString();
    }

    /**
     * 远程请求数据
     * 
     * @param dataMap 参数集合
     * @return 返回串
     */
    public abstract String requestRemote(Map<String, String> dataMap) throws RemoteAccessException;
}
