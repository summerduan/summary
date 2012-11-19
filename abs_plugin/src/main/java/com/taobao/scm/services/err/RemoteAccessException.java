/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.services.err;

/**
 * 远程接口调用异常。
 * 
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-3-29
 */
public class RemoteAccessException extends Exception {
    private static final long serialVersionUID = -660722901432626379L;

    public RemoteAccessException() {
        super();
    }

    public RemoteAccessException(String message, Throwable cause) {
        super(message, cause);
    }

    public RemoteAccessException(String message) {
        super(message);
    }

    public RemoteAccessException(Throwable cause) {
        super(cause);
    }
}
