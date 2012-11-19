/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.services;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-5-28
 */
public class ShellHelper {
    private static String[] parseKeyValue(String pairStr) {
        if (pairStr == null || pairStr.length() == 0) {
            return null;
        }
        int pos = pairStr.indexOf('=');
        if (pos == -1) {
            return null;
        }
        String[] retnPair = new String[2];
        retnPair[0] = pairStr.substring(0, pos);
        retnPair[1] = pairStr.substring(pos + 1, pairStr.length());
        return retnPair;
    }

    /**
     * 解析运行脚本的结果集。
     * 
     * @param filePath 文件路径
     */
    public static Map<String, Set<String>> getShellResult(String filePath) {
        Map<String, Set<String>> dataMap = new HashMap<String, Set<String>>();
        try {
            BufferedReader in = new BufferedReader(new FileReader(filePath));
            String str;
            while ((str = in.readLine()) != null) {
                String[] retnPair = parseKeyValue(str);
                if (retnPair == null) {
                    continue;
                }
                String key = retnPair[0];
                if (dataMap.containsKey(key)) {
                    dataMap.get(key).add(retnPair[1]);
                } else {
                    Set<String> val = new HashSet<String>();
                    val.add(retnPair[1]);
                    dataMap.put(key, val);
                }
            }
            in.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return dataMap;
    }
}
