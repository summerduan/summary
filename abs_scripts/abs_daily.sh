#
# (C) 2007-2010 Alibaba Group Holding Limited
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
#
# Version: $Id$
#
# Authors:
#   XueJiang <xuejiang@taobao.com>
#


##########################################################################
#       dailybuild脚本                                                   #
#DailyBuild依托于ABS的WORKSPACE，从ABS的WS里面取到SVN的URL。             # 
#然后做cppeck的代码检查，如果有cpp的代码的话。                           #
#接着进行build打rpm包。                                                  #
#如果打包成功，就上传到yum的dailubuild分支。                             #
#接着根据需要，触发TOAST，取daily的包进行自动化测试相关工作。            # 
#                                                                        #
##########################################################################


#!/bin/bash

#for check
#如果是ABS的“自动构建”触发起来的编译，则推出，这里做判断.
#PREFIX为必须的变量，这里可以判断。
if [ "$BUILDTYPE" = "" -a  "${PREFIX}" != "" ]
then
   echo "The build type is PrivateBuilding for signal OS,Exit the DailyBuild."
   exit 0
fi
if [ "$BUILDTYPE" = "" -a  "${IFREBUILD}" != "" ]
then
   echo "The build type is test or release Building for signal OS,Exit the DailyBuild."
   exit 0
fi


echo BUILDTYPE IS:$BUILDTYPE

BLDTYP="PRIVATE-BUILDING,TEST-BUILDING,RELEASE-BUILDING"
#这里还做判断，如果BUILDTYPE不为空，说明为ABS的多平台触发的，则推出
if [ "$BUILDTYPE" != "" ]
then
	if [ `echo $BLDTYP|grep "$BUILDTYPE"|wc -l` -gt 0 ]
	then
		echo "The BUILDTYPE isn't empty,And the BuildType is not DailyBuild!"
		exit 0
	fi
fi

#toast_t这里做初始化，默认为1。如果为0，则只做dailybuild，做做自动化测试。
#因为不是左右团队都有dailybuild完毕以后做自动化测试的需求。
toast_t=${1:-"0"}
## define Var ##
RPM_HOST="XXXX.taobao.com"
#JOB_NAME初始化，多平台的JOB_NAME不太一致，所以做了简单处理
JOB_NAME=`echo ${JOB_NAME} |awk -F'/' '{print $1}'`

##############SVN INFO############################
#SVN_INFO取svn info的函数
svn_info()
{
 str=`svn info 2>/dev/null |  
 awk -F': ' '{if($1=="URL") print $2}'`       
 if [ -z "$str" ]; then return; fi      
 svn_path=$str  
 echo $str
}
##############SVN INFO############################
#进入ABS的工作目录，$WORKSPACE是ABS自带的变量
cd ${WORKSPACE}/${JOB_NAME} 
svn_info
#############Check The CheckIn Yesterday############
#这里判断该svn url是否在昨日有更新，如果没有更新，则推出，不做Dailybuild。
OLDDATE=`date -d '-1 day' +%Y%m%d`
NEWDATE=`date   +%Y%m%d`
if [ `svn log -r{$OLDDATE}:{$NEWDATE} ${svn_path}|grep -v USERS|grep "^r[0-9]"|wc -l` -eq 0 ]
then
	if [ $toast_t != 2 ]
	then
		echo "No CheckIn In the Repos ${svn_path} during $OLDDATE  and  $NEWDATE,DailyBuild Exit!"
		exit 0
	fi
fi
#############Check The CheckIn Yesterday############

##############FOR CHECK DIR############################
#如果ABS的WS不存在，则推出，不做dailybuild的操作。因为ABS的WS是基础。

if [ ! -d "${WORKSPACE}/${JOB_NAME}" ]
then
  echo ${WORKSPACE}/${JOB_NAME} do not exists! 
  exit 1
fi
#如果存在上一次的dailybuild目录，则删除之。
if [  -d ${WORKSPACE}/${JOB_NAME}_daily ]
then
   rm -rf   ${WORKSPACE}/${JOB_NAME}_daily
fi
##############FOR CHECK DIR############################
#svn co 出代码

mkdir ${WORKSPACE}/${JOB_NAME}_daily
cd ${WORKSPACE}/${JOB_NAME}_daily
svn co ${svn_path} ./  --username=user  --password=pass  --non-interactive > null

###############################CppCheckResultOutPut###############################
#做cppcheck，代码检查
cd ${WORKSPACE}/${JOB_NAME}_daily
echo "cppcheck is start"
cppcheck  `find . -name "*.cpp"`   --xml  -q  2&>$WORKSPACE/Cppcheck-Result.xml
echo "cppcheck is end"
###############################CppCheckResultOutPut###############################


#cd rpm
#开始执行打包动作
cd ${WORKSPACE}/${JOB_NAME}_daily/rpm
APP_NAME=${JOB_NAME}
if [ -f ${JOB_NAME}-VER.txt ]
then
  VERS=`cat ${APP_NAME}-VER.txt`
else
  VERS=`cat ${APP_NAME}.spec|grep Version|cut -d ":" -f 2|sed "s/^ //g"`  
fi
echo $VERS

if [ -n "$USE_REVISION" ]
then
   SVN_RE=`svn info ../ 2>null|grep -E "Last Changed Rev:|^×ºóĵİ汾:" |awk -F': ' '{print $2}'`
   BUILD_NUMBER=$SVN_RE
fi
echo BUILD_NUMBER is :$SVN_RE


if [ -f ${JOB_NAME}-build.sh ]
then
  echo "${APP_NAME}-build.sh is start"
  sh ${APP_NAME}-build.sh ${WORKSPACE}/${APP_NAME}_daily ${APP_NAME} ${VERS} $BUILD_NUMBER
  echo "${APP_NAME}-build.sh is end"
else
  
  echo "rpm_create is start"
  rpm_create *.spec -p /home/a
  echo "rpm_create is end"
fi
cd ${WORKSPACE}/${JOB_NAME}_daily/rpm
#mv `find . -name ${JOB_NAME}*${VERS}*${BUILD_NUMBER}*rpm` .
 find . -name "$JOB_NAME*$VERS*$BUILD_NUMBER*rpm"  -exec mv {} . \;

if [ `find . -name "$JOB_NAME*$VERS*$BUILD_NUMBER*rpm"|wc -l` -eq 0 ]
then
echo "No rpm file like ${JOB_NAME} is Generated"
exit 1
fi

if [ `cat /etc/redhat-release|cut -d " " -f 7|cut -d "." -f 1` = 4 ]
then
        OSVER=4
else
        OSVER=5
fi
ARNUM=`uname -i`
RPMURL=""
RPMF=""
#打包完毕，以下是把打的包做处理
#1.上传到yum的dailybuild分支
#2.拷贝到另外一个服务器做备份，这个可以删除掉了。
for rpmfile in ${JOB_NAME}*${VERS}*${BUILD_NUMBER}*rpm
do
#yum-upload $rpmfile --osver $OSVER  --arch $ARNUM --group yum --batch
yum-upload-dailybuild $rpmfile --osver $OSVER  --arch $ARNUM --group yum --batch
ssh USER@"${RPM_HOST}" "if [ ! -d /home/a/share/htdocs/publish/${JOB_NAME} ] ; then mkdir /home/a/share/htdocs/publish/${JOB_NAME}; fi"
scp $rpmfile USERS@${RPM_HOST}:/home/a/share/htdocs/publish/${JOB_NAME}
RURL="http://XXX.taobao.com/publish/${JOB_NAME}/$rpmfile"
RPMURL=`echo $RPMURL\;$RURL`
RPMF=`echo $RPMF\;$rpmfile`
done
RPMURL=`echo $RPMURL|sed "s/^\;//g"`
RPMF=`echo $RPMF|sed "s/^\;//g"`
echo "The RPMURL is:$RPMURL"
master_test=`hostname`
echo "The master_test is :$master_test"
###########################################Excute the automation test###########################################
#执行自动化测试的动作
if [ $toast_t != 0 ]
then
	if [ "$AUTO_TEST_MASTER" = $master_test ] || [ "$AUTO_TEST_MASTER" = "" ]
	then 

	echo "Excute the automation test is start"
	request_url='http://XXX.taobao.com/XX/XXX'
	type=2
	project_id=$2
	user='ABS'
	build=$RPMF
	build_path=$RPMURL
	build_path=$(php -r  "echo urlencode('$build_path');")
	#curl -d "build_path=$build_path"  $request_url/project_id/$project_id/type/$type/build/$build/user/$user
	curl  $request_url/XXXX/$project_id/type/$type/XX/$build/XXX/$user
	echo "Excute the automation test is end"
	
	fi
fi
###########################################Excute the automation test###########################################
#ok，完毕
