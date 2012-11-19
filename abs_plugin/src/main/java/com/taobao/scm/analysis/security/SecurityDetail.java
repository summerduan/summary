/*
 * (C) 2007-2010 Alibaba Group Holding Limited
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 * 
 */
package com.taobao.scm.analysis.security;

import hudson.model.AbstractBuild;
import hudson.model.ModelObject;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Serializable;
import java.io.StringReader;
import java.io.StringWriter;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

import net.sf.json.JSONArray;
import net.sf.json.JSONObject;

import org.apache.commons.io.IOUtils;
import org.apache.commons.io.LineIterator;
import org.apache.commons.lang.StringEscapeUtils;
import org.apache.commons.lang.StringUtils;
import org.mozilla.intl.chardet.nsDetector;
import org.tmatesoft.svn.core.SVNException;
import org.tmatesoft.svn.core.SVNURL;
import org.tmatesoft.svn.core.internal.wc.DefaultSVNOptions;
import org.tmatesoft.svn.core.wc.SVNClientManager;
import org.tmatesoft.svn.core.wc.SVNRevision;
import org.tmatesoft.svn.core.wc.SVNWCClient;
import org.tmatesoft.svn.core.wc.SVNWCUtil;

import com.taobao.scm.services.err.RemoteAccessException;

import de.java2html.converter.JavaSource2HTMLConverter;
import de.java2html.javasource.JavaSource;
import de.java2html.javasource.JavaSourceParser;
import de.java2html.options.JavaSourceConversionOptions;

/**
 * 风险详细页面。
 * 
 * @author LingKan <lingkan@taobao.com>
 * @version 2010-3-30
 */
public class SecurityDetail implements ModelObject, Serializable {
    private static final long serialVersionUID = 5476103955694562835L;

    private static final int SOURCE_GENERATOR_OFFSET = 13;

    private static DefaultSVNOptions OPTIONS = SVNWCUtil.createDefaultOptions(true);

    private final AbstractBuild<?, ?> owner;

    public AbstractBuild<?, ?> getOwner() {
        return owner;
    }

    private final JSONObject data;

    public JSONObject getData() {
        return data;
    }

    private final String filename;

    public String getFilename() {
        return filename;
    }

    private String sourceCode;

    public String getSourceCode() {
        return sourceCode;
    }

    public void setSourceCode(String sourceCode) {
        this.sourceCode = sourceCode;
    }

    private final Set<Map<String, Object>> errList;

    public Set<Map<String, Object>> getErrList() {
        return errList;
    }

    private String charset = "UTF-8";

    public String getCharset() {
        return charset;
    }

    public void setCharset(String charset) {
        this.charset = charset;
    }

    public SecurityDetail(SecurityResult securityResult, String filename) throws RemoteAccessException, IOException, SVNException {
        this.owner = securityResult.getOwner();
        this.data = securityResult.getData();
        Map<String, String> config = securityResult.getConfig();
        Set<String> falsePositive = securityResult.getFalsePositive();
        this.filename = filename;

        JSONObject jo = this.data.getJSONObject("filestatistics").getJSONObject(filename);
        String svnUrl = jo.getString("svn");
        String revision = jo.getString("revision");
        JSONArray detail = jo.getJSONArray("detail");
        int size = detail.size();
        Set<Map<String, Object>> errList = new TreeSet<Map<String, Object>>(new Comparator<Map<String, Object>>() {
            @Override
            public int compare(Map<String, Object> o1, Map<String, Object> o2) {
                Integer lineNumb1 = Integer.valueOf((String) o1.get("lineNumb"));
                Integer lineNumb2 = Integer.valueOf((String) o2.get("lineNumb"));
                return lineNumb1.compareTo(lineNumb2);
            }
        });
        for (int i = 0; i < size; i++) {
            JSONArray ja = detail.getJSONArray(i);
            String id = ja.getString(0);
            String lineNumb = ja.getString(1);
            String errType = ja.getString(2);
            String[] lineNumbs = StringUtils.split(lineNumb, ",");
            for (String line : lineNumbs) {
                Map<String, Object> dataMap = new HashMap<String, Object>();
                dataMap.put("id", id);
                dataMap.put("lineNumb", line);
                dataMap.put("errType", errType);
                errList.add(dataMap);
            }
        }

        this.errList = errList;

        ByteArrayOutputStream dst = new ByteArrayOutputStream();

        SVNClientManager clientManager = SVNClientManager.newInstance(OPTIONS, config.get("username"), config.get("password"));
        SVNWCClient wcc = clientManager.getWCClient();
        wcc.doGetFileContents(SVNURL.parseURIDecoded(svnUrl), SVNRevision.UNDEFINED, SVNRevision.parse(revision), false, dst);
        byte[] dstBytes = dst.toByteArray();
        dst.close();

        ByteArrayInputStream bis = new ByteArrayInputStream(dstBytes);
        nsDetector det = new nsDetector(nsDetector.SIMPLIFIED_CHINESE);
        byte[] buf = new byte[1024];
        int len;
        boolean done = false;
        while ((len = bis.read(buf, 0, buf.length)) != -1 && !done) {
            done = det.DoIt(buf, len, false);
        }
        det.DataEnd();
        String prob[] = det.getProbableCharsets();
        if (prob.length > 0) {
            this.setCharset(prob[0]);
        }
        bis.close();

        InputStreamReader isr = new InputStreamReader(new ByteArrayInputStream(dstBytes), this.getCharset());
        this.splitSourceFile(falsePositive, this.highlightSource(isr));
        isr.close();
    }

    @Override
    public String getDisplayName() {
        return this.filename;
    }

    public final void splitSourceFile(Set<String> falsePositive, final String sourceFile) {
        StringBuilder output = new StringBuilder(sourceFile.length());

        LineIterator lineIterator = IOUtils.lineIterator(new StringReader(sourceFile));
        int lineCursor = 1;

        try {
            while (lineCursor < SOURCE_GENERATOR_OFFSET) {
                copyLine(output, lineIterator);
                lineCursor++;
            }
            lineCursor = 1;
            for (Map<String, Object> dataMap : this.errList) {
                Integer lineNumb = Integer.valueOf((String) dataMap.get("lineNumb"));
                while (lineCursor <= lineNumb) {
                    if (lineCursor == lineNumb) {
                        String id = (String) dataMap.get("id");
                        boolean bSkip = falsePositive.contains(id);
                        output.append("<a name=\"");
                        output.append((String) dataMap.get("lineNumb"));
                        String errMsg = this.getErrMsg((String) dataMap.get("errType"));
                        output.append("\"><div myId=\"");
                        output.append(id);
                        output.append("\"");
                        if (!bSkip) {
                            output.append(" onclick=\"YAHOO.errMsg.show(this);\"");
                        }
                        output.append(" tooltip=\"");
                        output.append(errMsg);
                        output.append("\" style=\"cursor: hand; cursor: pointer; background-color: ");
                        output.append(bSkip ? "#CCCCCC" : "#FCAF3E");
                        output.append(";\">");
                        output.append(lineIterator.nextLine());
                        output.append("</div></a>\n");
                    } else {
                        copyLine(output, lineIterator);
                    }
                    lineCursor++;
                }
            }
            while (lineIterator.hasNext()) {
                copyLine(output, lineIterator);
            }
        } catch (Exception e) {
            // NoP
        }
        this.sourceCode = output.toString();
    }

    public final String highlightSource(final InputStreamReader sourceFile) throws IOException {
        JavaSource source = new JavaSourceParser().parse(sourceFile);

        JavaSource2HTMLConverter converter = new JavaSource2HTMLConverter();
        StringWriter writer = new StringWriter();
        JavaSourceConversionOptions options = JavaSourceConversionOptions.getDefault();
        options.setShowLineNumbers(true);
        options.setAddLineAnchors(true);
        converter.convert(source, options, writer);

        return writer.toString();
    }

    private void copyLine(final StringBuilder output, final LineIterator lineIterator) {
        output.append(lineIterator.nextLine());
        output.append("\n");
    }

    private String getWarnMsg(String errType) {
        try {
            return this.data.getJSONObject("bugtypestatistics").getJSONObject(errType).getString("warnmsg");
        } catch (Exception e) {
            return "（无）";
        }
    }

    private String getHelpMsg(String errType) {
        try {
            return this.data.getJSONObject("bugtypestatistics").getJSONObject(errType).getString("helpmsg");
        } catch (Exception e) {
            return "（无）";
        }
    }

    private String getErrMsg(String errType) {
        StringBuffer strb = new StringBuffer();
        strb.append("风险描述:<br/>");
        strb.append(StringEscapeUtils.escapeHtml(this.getWarnMsg(errType)));
        strb.append("<br/>帮助信息:<br/>");
        strb.append(StringEscapeUtils.escapeHtml(this.getHelpMsg(errType)));
        return strb.toString();
    }
}
