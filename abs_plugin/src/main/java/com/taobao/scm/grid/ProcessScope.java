/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.grid;

import java.util.HashSet;
import java.util.Set;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-6-8
 */
public class ProcessScope {
    private static final String SEPARATOR = ":";

    private static String spliceKey(String processType, String processStep) {
        return new StringBuffer().append(processType).append(SEPARATOR).append(processStep).toString();
    }

    public static final class Packet {
        private final Set<String> gridScope;

        public Set<String> getGridScope() {
            return gridScope;
        }

        public Packet(String[] gridScope) {
            this.gridScope = new HashSet<String>();
            for (String scope : gridScope) {
                if (scope.indexOf(SEPARATOR) != -1) {
                    this.gridScope.add(scope);
                }
            }
        }

        public boolean contains(String processType, String processStep) {
            String gridScope = spliceKey(processType, processStep);
            return this.gridScope.contains(gridScope);
        }
    }

    public ProcessType[] getProcessTypes() {
        return ProcessType.values();
    }

    public ProcessStep[] getProcessSteps(String typeCode) {
        return ProcessType.getProcessSteps(typeCode);
    }

    public String spliceHtml(String typeCode, String stepCode, String stepName, Object packet) {
        StringBuffer strb = new StringBuffer();
        strb.append("<option value=\"");
        strb.append(spliceKey(typeCode, stepCode));
        strb.append("\"");
        if (packet != null && packet instanceof Packet && ((Packet) packet).contains(typeCode, stepCode)) {
            strb.append(" selected=\"selected\"");
        }
        strb.append(">");
        strb.append(stepName);
        strb.append("</option>");
        return strb.toString();
    }
}
