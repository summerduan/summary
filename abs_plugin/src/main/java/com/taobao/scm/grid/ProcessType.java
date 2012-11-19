/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.grid;

import java.util.HashMap;

/**
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-5-31
 */
public enum ProcessType {
    PROCESS("process", "模式一", false, new ProcessStep[] { ProcessStep.DEV, ProcessStep.QA, ProcessStep.PE }),

    PRIMARY("primary", "模式二", false, new ProcessStep[] {
            ProcessStep.MERGE_SOURCE,
            ProcessStep.CONFILCT_RESOLVED,
            ProcessStep.MERGE_BUILDING,
            ProcessStep.RELEASE_BUILDING,
            ProcessStep.PE_UNLOCK });

    private static HashMap<String, ProcessStep[]> CONTAINER = new HashMap<String, ProcessStep[]>(ProcessType.values().length);

    static {
        for (ProcessType processType : ProcessType.values()) {
            CONTAINER.put(processType.getCode(), processType.getProcessSteps());
        }
    }

    public static ProcessStep[] getProcessSteps(String code) {
        return ProcessType.CONTAINER.get(code);
    }

    private final String code;

    public String getCode() {
        return code;
    }

    private final String name;

    public String getName() {
        return name;
    }

    private final boolean off;

    public boolean isOff() {
        return off;
    }

    private final ProcessStep[] processSteps;

    public ProcessStep[] getProcessSteps() {
        return processSteps;
    }

    private ProcessType(String code, String name, boolean off, ProcessStep[] processSteps) {
        this.code = code;
        this.name = name;
        this.off = off;
        this.processSteps = processSteps;
    }
}
