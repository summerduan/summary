package com.taobao.scm.grid;

import hudson.Extension;
import hudson.model.AbstractBuild;
import hudson.model.Action;
import hudson.model.Actionable;
import hudson.model.Cause;
import hudson.model.ParameterValue;
import hudson.model.ParametersAction;
import hudson.model.StringParameterValue;
import hudson.model.TaskListener;
import hudson.model.Cause.UserCause;
import hudson.model.listeners.RunListener;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

import com.taobao.scm.grid.ProcessWrapper.ProcessBuildAction;

@Extension
@SuppressWarnings("unchecked")
public class ProcessListener extends RunListener<AbstractBuild> {
    private static final String DEC_FIELD = "parameters";

    private static final String DEC_ACTIONS = "actions";

    private static Field parametersField;

    private static Field actionsField;

    static {
        try {
            parametersField = ParametersAction.class.getDeclaredField(DEC_FIELD);
            parametersField.setAccessible(true);

            actionsField = Actionable.class.getDeclaredField(DEC_ACTIONS);
            actionsField.setAccessible(true);
        } catch (SecurityException e) {
            e.printStackTrace();
        } catch (NoSuchFieldException e) {
            e.printStackTrace();
        }
    }

    public ProcessListener() {
        super(AbstractBuild.class);
    }

    @Override
    public void onStarted(AbstractBuild r, TaskListener listener) {
        try {
            // 初始化构建参数环境
            setInitParams(r, true);
        } catch (IllegalArgumentException e) {
            listener.getLogger().println(e);
        } catch (IllegalAccessException e) {
            listener.getLogger().println(e);
        }
    }

    /**
     * 返回回调参数队列。
     */
    public static List<ParameterValue> getParamsList(AbstractBuild<?, ?> build)
            throws IllegalArgumentException, IllegalAccessException {
        return setInitParams(build, true);
    }

    /**
     * 设置回调参数队列。
     * 
     * @param force 是否强制初始化
     */
    private static List<ParameterValue> setInitParams(AbstractBuild<?, ?> build, boolean force)
            throws IllegalArgumentException, IllegalAccessException {
        // 初始化参数环境
        ParametersAction parametersAction = build.getAction(ParametersAction.class);

        boolean isInited = parametersAction != null;

        if (!isInited) {
            parametersAction = new ParametersAction(new ArrayList<ParameterValue>());
            CopyOnWriteArrayList<Action> actions = (CopyOnWriteArrayList<Action>) actionsField.get(build);
            if (actions == null) {
                actions = new CopyOnWriteArrayList<Action>();
            }
            actions.add(parametersAction);
        }

        // 参数队列
        List<ParameterValue> ls = (List<ParameterValue>) parametersField.get(parametersAction);

        if (!isInited || force) {
            setInitParams(build, ls);
        }

        return ls;
    }

    /**
     * 设定初始化参数队列。
     */
    private static void setInitParams(AbstractBuild<?, ?> build, List<ParameterValue> ls) {
        {// 添加调用者信息
            String userName = "UNKNOWN";
            ProcessBuildAction processBuildAction = build.getAction(ProcessBuildAction.class);
            if (processBuildAction != null) {
                userName = processBuildAction.getCaller();
            } else {
                List<Cause> causes = build.getCauses();
                for (Cause cause : causes) {
                    if (cause instanceof UserCause) {
                        userName = ((UserCause) cause).getUserName();
                        break;
                    }
                }
            }
            StringParameterValue caller = new StringParameterValue("CALLER", userName);
            if (!ls.contains(caller)) {
                ls.add(new StringParameterValue("CALLER", userName));
            }
        }
    }
}
