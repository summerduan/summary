#!/bin/bash
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

##for check

#/home/abs/abs_scripts/abs_c.sh ${TYPE} ${SVNURL} ${BUILDPASS} ${VER} ${REALPASS} ${IFREBUILD}

# buildmaster is the hostname of your hudson server
# 请修改为你hudson的实际hostname
export absmaster="build.example.com"

# yumserver is the hostname of your yum server (packages server)
#请修改为你yum服务器的实际hostname
yumserver="http://yum.example.com"

#管理员邮箱地址
adminEmail="admin1@example.com,admin2@example.com"

# 假设运行abs_c.sh的用户是abs用户，请修改为你的实际用户
# 注：同时本脚本假设了hudson安装在$buildmaster:/home/abs/.hudson/ 目录下
# 请搜索本脚本的'abs'关键字
export ABS_PATH="/home/abs/"

# 修改为你的svn用户名和密码,ABS将使用此用户密码访问你的svn
svnuser=" --username=XXX --password=***"

##---------
# Dochanglist()函数打印出变更列表（变更列表没用到），给出自动review中用到的版本号rev0
#----------
function Dochangelist()
{
	svnurl1=`cat ${ABS_WORKSPACE}/${APP_NAME}/$SUB_DIR/rpm/SVNPREFIX.txt`
        svnurl2=`cat ${ABS_WORKSPACE}/${APP_NAME}/$SUB_DIR/rpm/SVNSUFFIX.txt`
	br_flag=0
	if [[ "$svnurl2" =~ .*branches.* ]];then
		br_flag=1
		brn=`echo $svnurl2|awk -F'branches/' '{print $2}'`
		brn=${brn//\//}
		#按分支名存储版本号
		if [ -e "${ABS_WORKSPACE}/${brn}-$1-rev2.txt" ]
        	then
				echo "[ABS_INFO]${ABS_WORKSPACE}/${brn}-$1-rev2.txt exist"
				rev1=`cat ${ABS_WORKSPACE}/${brn}-$1-rev2.txt`
				if [[ ! $rev1 =~  ^[0-9]+$ ]];then
					rev1=`svn info 2>null|grep -E "Revision:|^版本:" |awk -F':' '{print $2}'`
				fi

		else
				echo "[ABS_INFO] ${ABS_WORKSPACE}/${brn}-$1-rev2.txt doesn't exist"
				rev1=`svn info 2>null|grep -E "Revision:|^版本:" |awk -F':' '{print $2}'`
	        fi
	else
	        if [ -e "${ABS_WORKSPACE}/${APP_NAME}-$1-rev2.txt" ]
        	then
				echo "[ABS_INFO]${ABS_WORKSPACE}/${APP_NAME}-$1-rev2.txt exist"
				rev1=`cat ${ABS_WORKSPACE}/${APP_NAME}-$1-rev2.txt`
				if [[ ! $rev1 =~  ^[0-9]+$ ]];then
					rev1=`svn info 2>null|grep -E "Revision:|^版本:" |awk -F':' '{print $2}'`
				fi
		else
				echo "[ABS_INFO] ${ABS_WORKSPACE}/${APP_NAME}-$1-rev2.txt doesn't exist"
				rev1=`svn info 2>null|grep -E "Revision:|^版本:" |awk -F':' '{print $2}'`
	        fi
	fi
	rev2=`svn info 2>null|grep -E "Revision:|^版本:"  |awk -F':' '{print $2}'`
	if [ $br_flag == 1 ];then
		echo $rev2 >${ABS_WORKSPACE}/${brn}-$1-rev2.txt
	else
		echo $rev2 >${ABS_WORKSPACE}/${APP_NAME}-$1-rev2.txt
	fi
	export rev0=`echo  $rev1|tr -d ' '`
	if [[ ! $rev0 =~  ^[0-9]+$ ]];then
		echo "[ABS_Warning] couldn't get the svn source revision! The svn version:"
		svn --version -q
	fi
	rev=`echo  $rev2|tr -d ' '` 
	export br_flag brn
	echo "svn log -v --xml -r $rev0:$rev $svnurl1$svnurl2>${ABS_WORKSPACE}/$1-changelog.xml"
	svn log -v --xml -r $rev0:$rev $svnurl1$svnurl2>${ABS_WORKSPACE}/$1-changelog.xml 2>null
	TMP_NAME=$(echo ${ABS_WORKSPACE} |  awk -F'/' '{print $6}')
	scp ${ABS_WORKSPACE}/$1-changelog.xml ads@$absmaster:${ABS_PATH}/.hudson/jobs/${TMP_NAME}/builds/${BUILD_NUMBER}/changelog.xml
	true	
				#http://$absmaster:8080/reload
}
##--------
#从spec文件中获取版本号，或者从VER.txt中获取版本号。优先从VER.txt中获取。用VER.txt控制版本号可以使多个spec共用一个版本号。
#---------
function getVersion()
{
   cd $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR/rpm
   if [ -e ${APP_NAME}-VER.txt ]
   then
	version=`cat ${APP_NAME}-VER.txt`
   else
	version=`cat ${APP_NAME}.spec|grep ^Version|cut -d ":" -f 2|sed "s/^ //g"` 
   fi
   echo $version
}
##-------
#从hudson界面获取版本号输入到spec文件或VER.txt文件中
#-------
function inputVersion()
{
   cd $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR/rpm
   if [ -e ${APP_NAME}-VER.txt ]
   then
	echo $1 > ${APP_NAME}-VER.txt
   else
 	sed -i  "s/^Version:.*$/Version:"$1"/"  `pwd ${APP_NAME}.spec`/${APP_NAME}.spec 
   fi
}
##----------
# 将打出的rpm包上传到公司的yum服务器，同时打标签（A标签、R标签）
##----------
function DoDelivery()
{
        cd $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR/rpm
        echo "$1" >${APP_NAME}-stauts.txt
        version=$(getVersion)
        buildno=`cat BUILDNO.txt`
	echo "NO_TAG status is: $NO_TAG"
	if [ -z "$NO_TAG" ];then
	  tag=${version//./_}
          tag1=${APP_NAME}_$1_$tag
	  mydate=`date "+%Y%m%d" `
          tagname="$tag1"_${buildno}_$mydate
          echo tagname:$tagname
          #cd ..
          export ABS_URL=`cat SVNPREFIX.txt`
          echo ABS_URL is $ABS_URL

          TAG_URL=$ABS_URL"$3"
        
        
          #`echo $ABS_URL |sed -e "s/trunk/tags/"`
          echo TAG_URL is: $TAG_URL'/'$tagname
          cd ..
          svn copy . $TAG_URL'/'$tagname -m $2"-Building-$4- `date "+%Y%m%d %H:%M:%S" ` " $svnuser  --non-interactive 2>null 
			if [ $? -eq 1 ];then
		       echo "[ABS_Warning]: false to make svn tags! With comments $2 $4 "
	  		fi
          temp_name=`cat /etc/rpm/macros|awk '{if($1=="%dist") print $2}'`
          echo RPM_NAME is ${APP_NAME}-${version}-${buildno}${temp_name}.${plat}.rpm

          cd rpm
  	fi
#一个spec文件多个rpm包产生时的处理：在build forQA、forPE时定义MULTI_PK变量，值为包名
	t_pk_array=(${APP_NAME})
	if [ -n "$MULTI_PK" ];then
		t_pk_l=${MULTI_PK//,/ }
		[ -z "$t_pk_l" ] && t_pk_l=${APP_NAME}
		t_pk_array=($t_pk_l)
	fi
	for pk_name in ${t_pk_array[*]}
	do
		if [ "$DEBUG" == "true" ];then
			pk_name='';
		fi

	  if [[ `echo ls *.rpm ` =~ "\.noarch\." ]]
	  then
		if [ $1 == "A" ]
		then
			if [ ! -f ${pk_name}-${version}-${buildno}*.rpm ];then
				echo "Error: ${pk_name}-${version}-${buildno}*.rpm do not exists!"
				exit 3
			fi
			# 注：yum-upload是淘宝的yum上传工具，用于将rpm包上传到yum服务器的test分支。
	        	yum-upload ${pk_name}-${version}-${buildno}*.rpm  --osver $ABS_OS --arch noarch --group yum --batch
			# NOOS变量为真时，rpm包同时上传到4u和5u上。注：大写变量基本都是直接从hudson中传入。
			exit_code=$?
			if [ "$NOOS" == 1 ] 
			then
				if [ "$ABS_OS" == 4 ]
				then
					yum-upload ${pk_name}-${version}-${buildno}*.rpm  --osver 5 --arch noarch --group yum --batch
				else
					yum-upload ${pk_name}-${version}-${buildno}*.rpm  --osver 4 --arch noarch --group yum --batch
				fi
				exit_code=$?
			fi


		else
			#SELF_RELEASE为真时，使用自定义的${appname}-buildpe.sh进行上传yum上。
			# 注：yum-setbranch是淘宝的yum上传工具，用于将rpm包移动到指定分支。
			[ "$SELF_RELEASE" != 1 ] && yum-setbranch  ${pk_name}-${version}-${buildno} $ABS_OS noarch current
			exit_code=$?
			if [ "$NOOS" == 1 ] 
			then
			  if [ "$ABS_OS" == 4 ]
			  then
				[ "$SELF_RELEASE" != 1 ] && yum-setbranch  ${pk_name}-${version}-${buildno} 5 noarch current
			  else
				[ "$SELF_RELEASE" != 1 ] && yum-setbranch  ${pk_name}-${version}-${buildno} 4 noarch current
			  fi
			  exit_code=$?
		        fi
			[ "$SELF_RELEASE" == 1 ] && exit_code=${exit_code2}

		fi
	  else
		if [ "$NOOS" == 1 ];then
			echo "[ABS_WARNING]:this package is not noarch!"
		fi
		if [ $1 == "A" ]
		then
			if [ ! -f ${pk_name}-${version}-${buildno}*.rpm ];then
				echo "Error: ${pk_name}-${version}-${buildno}*.rpm do not exists!"
				exit 3
			fi
		        yum-upload ${pk_name}-${version}-${buildno}*.rpm  --osver $ABS_OS --arch ${plat} --group yum --batch
			exit_code=$?
		
		else
			[ "$SELF_RELEASE" != 1 ] && yum-setbranch  ${pk_name}-${version}-${buildno} $ABS_OS ${plat} current
			exit_code=$?
		fi
		[ "$SELF_RELEASE" == 1 ] && exit_code=${exit_code2}
	  fi
      done
      if [ "$exit_code" == "2" ];then
	      exit_code=0
      fi
      echo "$2 Building--Target RPM URL is: $yumserver/cgi-bin/yuminfo?name=${APP_NAME}--RPMNAME: ${APP_NAME}-${version}-${buildno}${temp_name}.${plat}.rpm--$tagname--"`date '+%Y%m%d %H:%M:%S' ` >>${LOGFILE}
        #--tag,publish,hunson promoted,email



}
#--------
#获取编译产生的rpm包名存放在shell_output.txt文件中。用于ABS插件调用toast进行自动BVT测试。
#--------
function getNewRpm()
{
	cd $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR/rpm
	TMP_NAME=$(echo ${ABS_WORKSPACE} |  awk -F'/' '{print $6}')
	scp ads@$absmaster:${ABS_PATH}/.hudson/jobs/${TMP_NAME}/builds/${BUILD_NUMBER}/abs_rpm.log ./ 2>null
	scp ads@$absmaster:${ABS_PATH}/.hudson/jobs/${TMP_NAME}/builds/${BUILD_NUMBER}/shell_output.txt ./ 2>null
	oldrpm=(`cat abs_rpm.log`)
	newrpm=(`ls *.rpm`)
	local count=${#newrpm[@]}
	local j=-1
	local mystr=''
	while [ "$j" -lt "$count" ]
	do
		let "j = $j + 1"		
		for name2 in ${oldrpm[*]}
		do
			if [ "${newrpm[$j]}" == "${name2}" ]
			then
				unset newrpm[$j]
				continue
			fi
		done
		if [ -n "${newrpm[$j]}" ]
		then
			mystr="toast=${newrpm[$j]}"
			echo ${newrpm[$j]} >> ./abs_rpm.log
			echo $mystr >>./shell_output.txt
		fi
	done
	scp ./abs_rpm.log ads@$absmaster:${ABS_PATH}/.hudson/jobs/${TMP_NAME}/builds/${BUILD_NUMBER}/
	scp ./shell_output.txt ads@$absmaster:${ABS_PATH}/.hudson/jobs/${TMP_NAME}/builds/${BUILD_NUMBER}/
}
#-----
#发送邮件函数，当reviewboard异常时发送邮件给管理员
#-----
function warnEmail()
{
        msg=$2;
        echo "msg: "$msg;
        address=$1;
	subj=$3;
        echo "sending email : \"ReviewBoard:${msg}\""
        mail_command=`which mail`;
        echo "ReviewBoard:${msg}" | ${mail_command} -s "ReviewBoard:${subj}" ${address}
}
function autoplus()
{
	#自动增加版本号

		if [ "$ver" == "0" ];then
			if [ -f $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR/rpm/${APP_NAME}-stauts.txt ];then
				abs_st=`cat $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR/rpm/${APP_NAME}-stauts.txt`
				if [[ "$ABS_BRANCHES" =~ .*branches.* ]] &&  [ -n $CHECK_ON_TRUNK ] 
				then
					return;
				fi
				if [ "$abs_st" == "R" ] &&  [ "$ALLOW_SAME" != 1 ]
				then
					ver=1
					echo "[ABS_INFO]rpm version will auto plus 1"
				fi
			fi
		fi
}
if [ $# -lt 1 ]
   then
      echo "Usage:abs_c.sh <Private-Building|Test-Building|Release-Building>"
      exit 2
fi

if [ $# -lt 2 ]
   then
      echo "[ABS_ERROR] The second Parameters can't be null! "
      exit 2
fi

if [ `uname -i` == "x86_64" ]
then
        plat="x86_64"
else
        plat="i386"
fi

export APP_NAME=`echo ${JOB_NAME} |awk -F'/' '{print $1}'`
APP_NAME=${APP_NAME// /}

target=1
mylang='C'
#设置脚本运行时的编码，可在hudson的job中配置。使得可以checkout一些中文编码的svn文件。
#如不设置则是系统默认编码，一般是utf-8编码。
if [ -f $WORKSPACE/lang.txt ];then
	mylang=`cat $WORKSPACE/lang.txt`
fi
if [ -n "$MYLANG" ];then
       mylang=$MYLANG
       echo $mylang > $WORKSPACE/lang.txt
       echo "[ABS_INFO] the env will use the locale lang: $MYLANG"
else
	rm $WORKSPACE/lang.txt
fi
LANG=$mylang
export LANG

TEMP=`getopt -o p:r:t:h -- "$@"`
eval set -- "$TEMP"

while true ; do
  case "$1" in
    -h) usage; shift ;;
    -p) APP_NAME=$2; shift 2 ;;
    -r) ABS_COMMENT=$2; shift 2 ;;
    -t) target=$2; shift 2 ;;
    --) shift; break;;
    *) echo "Internal error!"; exit 1;;
  esac
done


export ABS_WORKSPACE=$WORKSPACE
export ABS_BUILD_NUMBER=$BUILD_NUMBER
if [  -d $ABS_WORKSPACE ];then
	echo ""
else
	echo "[ERROR]: the workspace $ABS_WORKSPACE do not exists!"
	exit 1
fi
echo ABS_WORKSPACE is:$ABS_WORKSPACE
echo ABS_BUILD_NUMBER is : $ABS_BUILD_NUMBER
echo Build_Server_Plat is: $plat
echo APP_NAME is: ${APP_NAME}
#
#获得操作hudson的当前用户名
#
if [ -n "$CALLER" ];then
	echo $CALLER > $ABS_WORKSPACE/abs_caller
fi
export ABS_OS=`cat /etc/redhat-release |awk '{print $7}'|awk -F'.' '{print $1}'`
echo ABS_OS is $ABS_OS


if [ -z $ABS_WORKSPACE ] 
then
        echo "[ABS_ERROR] The ABS_WORKSPACE Parameters can't be null "
        exit 2
fi

#`date +%Y%m%d`
LOGFILE="${ABS_PATH}abs_logs/${APP_NAME}.log"

case $1 in
  PRIVATE-BUILDING)
  #本段脚本负责从svn上check out最新代码，并调用各自build.sh脚本进行编译、打包。另外，配置编译环境、发起自动review等功能。
                  echo SVNURL is: $2$4
                  cd $ABS_WORKSPACE
		  ver=$3

                  export input=$2$4;
                  svn_svr=`echo $input |awk -F'/' '{print $4}'`
#进行svn目录格式检查
	       t_rpm_e=`svn info $2$4/rpm $svnuser --non-interactive | wc -l`
		if [ "$t_rpm_e" -lt 2 ];
		then
			echo "Error: $2$4/rpm don't exists!"
		   	exit 1
		fi
		svn info $2$4/rpm/${APP_NAME}-VER.txt $svnuser --non-interactive 2>null > svncheck2.log 
		svn info $2$4/rpm/${APP_NAME}.spec $svnuser --non-interactive 2>null >> svncheck2.log
		t_file_e=`cat svncheck2.log | wc -l`
	        if [ "$t_file_e" -lt 2 ];
		then
			echo "Error: Neither ${APP_NAME}-VER.txt nor ${APP_NAME}.spec exists!"
		   	exit 1
		fi

#根据-t参数，决定是重新checkout还是用update
#BRANCH_MOD=true时：分支模式，支持不同分支交叉编译。
#否则就是共用同一个workspace
		if [ "$BRANCH_MOD" == "true" ];then
			SUB_DIR=$4
		fi
		export ABS_BRANCHES=$4
		autoplus	

		#------------
		#ALLOW_UPDATE为真时，每次编译只是进行svn up，而不是进行svn checkout。用于代码量较大的job。不推荐。
 	       if [ "$ALLOW_UPDATE" == "1" ]
	       then
                    cd $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR/
                    echo target is: $target
                    rm -rf rpm
                    svn cleanup 2> svnup.err
                    svn update $svnuser --force --non-interactive
                    svnerr=`cat svnup.err | wc -c`
		    if [ "$svnerr" -gt 1 ]
		    then
			    mkdir -p $ABS_WORKSPACE/${APP_NAME}
			svn checkout  $2$4 $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR $svnuser  --non-interactive > svnco.log
		    	tail -n 1 svnco.log		    
		    fi
	       else
                  if [ -e "${ABS_WORKSPACE}/${APP_NAME}" ]
                  then
                    [ -d "${ABS_WORKSPACE}" ] && rm -rf $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR/
		    echo "rm -rf $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR/ is done"
                    cd $ABS_WORKSPACE
		    echo svn checkouting ....
                    svn checkout $2$4 ${APP_NAME}/$SUB_DIR $svnuser --non-interactive > svnco.log
		    mkdir -p $ABS_WORKSPACE/${APP_NAME}
		    tail -n 1 svnco.log
                  else
		    echo svn checkouting ...
            svn checkout $2$4 ${APP_NAME}/$SUB_DIR $svnuser  --non-interactive > svnco.log
			mkdir -p $ABS_WORKSPACE/${APP_NAME}
		    tail -n 1 svnco.log
                  fi
              fi

      ln -s -f "$ABS_PATH"abs_logs/${APP_NAME}.log $ABS_WORKSPACE/${APP_NAME}.log
      cd $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR/rpm
		#$ver为脚本调用的第三个参数，决定版本号的处理，当值为0时版本不变，为1时版本加1，其他时为用户输入。
      if  [ "$ver" = 0 ]
      then
	      echo "[ABS_INFO] rpm version will be ( no changed ):"
          version=$(getVersion)
          echo $version
      elif [ "$ver" = 1 ]
      then	      
	      #版本号+1
        version=$(getVersion)
	TMP_NAME=$(echo ${ABS_WORKSPACE} |  awk -F'/' '{print $6}')
	scp ads@$absmaster:${ABS_PATH}/.hudson/jobs/${TMP_NAME}/builds/${BUILD_NUMBER}/VER_exist.abs.txt ./ 2>null
	if [ -f VER_exist.abs.txt ]
	then
		  version=$(cat VER_exist.abs.txt)
		  inputVersion "$version"
	else
          	if [[ "$version" =~ "([0-9]+.[0-9]+).([0-9]+)" ]]
          	then
             		version2=`expr ${BASH_REMATCH[2]} + 1`
             		echo "[ABS_INFO]rpm versionno plus 1:"${BASH_REMATCH[1]}"."$version2
	                inputVersion ${BASH_REMATCH[1]}"."$version2 
	             	version=$(getVersion)
			echo $version > VER_exist.abs.txt
			scp VER_exist.abs.txt ads@$absmaster:${ABS_PATH}/.hudson/jobs/${TMP_NAME}/builds/${BUILD_NUMBER}/
          	fi
	fi
      else
	      #采用用户输入的版本号
          inputVersion $3 
          echo "[ABS_INFO]rpm version will be your input charater:"$version
          version=$3
      fi
#检查同版本是否已经上传到yum的current分支上。
      if [[ "$version" =~ ^[0-9.-]+$ ]]
      then
        echo "match version format: " $BASH_REMATCH
	if [ -n "$CHECK_ON_TRUNK" ];then
		if [[ "$4" =~ "trunk" ]];then
			trunk_flag=1;
		else
			trunk_flag=0;
		fi
		echo "[ABS_INFO]:CHECK_ON_TRUNK=$CHECK_ON_TRUNK, ABS will only check the yum version while building on trunk ."
	fi
	[ -z "$PE_NAME" ] && PE_NAME=${APP_NAME}
        yum deplist ${PE_NAME}-$version -b current|grep -E "^package:"
        if [ $? -eq 0 ] &&  [ "$ALLOW_SAME" != 1 ] && [ "$trunk_flag" != 0 ]
        then
            echo Error:The version ${APP_NAME}-$version is already exists at the YUM-package server! Please input another version number
	     exit 1
        else
		echo "[ABS_INFO]ALLOW_SAME(allow same versions upload to yum_current) status is: $ALLOW_SAME ;trunk_flag status=$trunk_flag"
                echo "[ABS_INFO]have no version as $BASH_REMATCH, your action is allowed to take"
        fi
     else
	     #current分支版本已有时，版本号应当升1
        echo "Error: input charactors  [version] are illegal, it seems not a version number!"
        exit 1
     fi
###############
   if [ -e ${APP_NAME}-VER.txt ]
   then
     svn commit ${APP_NAME}-VER.txt -m "ABS-Version Change `date "+%Y%m%d %H:%M:%S" ` " $svnuser  --non-interactive > NULL
   else
     svn commit ${APP_NAME}.spec -m "ABS-Version Change `date "+%Y%m%d %H:%M:%S" ` " $svnuser    --non-interactive > NULL
   fi
     release=$ABS_BUILD_NUMBER
     echo $ABS_BUILD_NUMBER >BUILDNO.txt
     #USE_REVISION为真时，release号采用svn的revision号。否则采用全局的build number
     if [ -n "$USE_REVISION" ]
     then
	rev1=`svn info ../${REVISION_DIR} 2>null|grep -E "Last Changed Rev:|^最后修改的版本:" |awk -F':' '{print $2}'`
	echo $rev1 > BUILDNO.txt
     fi
     echo $2 >SVNPREFIX.txt
     echo $4 >SVNSUFFIX.txt
  #sed s/VERSION/$version/g  ${APP_NAME}.spec.temp|sed s/RELEASE/$release/g|sed s/APPNAME/${APP_NAME}/g> ${APP_NAME}.spec

  #  cd ..

     ###############
     # get the list of allowed-degrade from build4/pkdgAllowed.txt
     ###############
     scp ads@$absmaster:${ABS_PATH}/abs_scripts/pkgAllowed.txt ${ABS_PATH}/abs_scripts/ 2>null
     scp ads@$absmaster:${ABS_PATH}/abs_scripts/pkg_back.txt ${ABS_PATH}/abs_scripts/ 2>null     
     ###########3###
     #get the lists of ceiling pkg allowed to upgrade.
     ######### 
     scp ads@$absmaster:${ABS_PATH}/abs_scripts/pkg_top.txt ${ABS_PATH}/abs_scripts/ 2>null
     [ $? -eq 1 ] && rm ${ABS_PATH}/abs_scripts/pkg_top.txt
	 
     #pkgAllow：定义可以卸载降级的rpm包，不要定义成系统包。否则损坏系统
     pkgAllow="AliWS|algo|kfc|kagent"
     if [ -f ${ABS_PATH}/abs_scripts/pkgAllowed.txt ];then
     	pkgAllow=$(cat ${ABS_PATH}/abs_scripts/pkgAllowed.txt)
     fi	
    
     #*****
     # record the version before update!
     #*****
     if [ -f  ${ABS_PATH}/abs_scripts/pkg_back.txt ];then
     	tmp=$(cat ${ABS_PATH}/ads/abs_scripts/pkg_back.txt)
	if [ -n "$tmp" ];then
	       [ -n "$BACK_AFTER" ] && BACK_AFTER=$tmp
        fi
     fi
     if [ -n "$BACK_AFTER" ];then
		BACK_AFTER=${BACK_AFTER//,/ }
		echo "[ABS_INFO]$BACK_AFTER is set to history back after building."		
		unset my_back_after
	     for pkgtoback in $BACK_AFTER
	     do
		tmpv=`rpm -qv $pkgtoback`
		if [ $? -eq 1 ];then
			continue
		fi
		echo "[ABS_INFO]$tmpv is installed before update."
		my_back_after=" $tmpv $my_back_after"
	     done
     fi

     #****
     # del the pacakges before building.
     #****
     if [ -n "$DEL_PKG" ];then
		DEL_PKG=${DEL_PKG//,/ }
   		echo "[ABS_INFO]$DEL_PKG will be remove from buildhost"		
	     for pkgtodel in $DEL_PKG
	     do
		     while [ -f ~/${pkgtodel}.pid ];do
			     sleep 5
			     echo "couldn't to remove the package, $pkgtodel is locked now!"
		     done
		sudo rpm -e $pkgtodel --nodeps
		echo "[ABS_INFO]$pkgtodel is removed!"
	     done
     fi

     #****
     # install the pacakges before building from stable. 
     #****
     if [ -n "$INSTALL_PKG" ];then
		INSTALL_PKG=${INSTALL_PKG//,/ }
   		echo "[ABS_INFO]$INSTALL_PKG will be installed befor building"		
	     for pkgtodel in $INSTALL_PKG
	     do
		     while [ -f ~/${pkgtodel}.pid ];do
			     sleep 5
			     echo "couldn't to install the package, $pkgtodel is locked now!"
		     done
		sudo yum install $pkgtodel -y
		sudo yum install $pkgtodel -b current -y
		echo "[ABS_INFO]$pkgtodel is installed!"
	     done
     fi

     #***
     # exclude another building to change the same pkg.
     #***
if [ -e ~/abs.id ]
then
	runid=$(cat ~/abs.id)
	let "runid = $runid + 1"
	echo $runid > ~/abs.id
else
  runid=1
  echo $runid > ~/abs.id
fi
while [ -f ~/avatar.id ]
do
	echo "avatar is running! pls wait for a moment! --by `cat ~/avatar.id`"
	sleep 5
done

     echo "[ABS_INFO]$pkgAllow is allowed to degrade."
   #如果配置了阿凡达，则在编译前将系统还原成阿凡达快照状态
     if [ -n "$WALLE" ];then
	wallename=`hostname`
	wallename="${WALLE}_$wallename"
	echo "[ABS_INFO]Begin walle the env to $wallename, log is in:${APP_NAME}/walle.log"
	echo "$APP_NAME" > ~/avatar.id
	sudo /usr/local/bin/walle -y -n $wallename > $WORKSPACE/${APP_NAME}/walle.log 2>&1
     fi
     spec_file=${APP_NAME}.spec
     [ -n "$SPEC_NAME" ] && spec_file=$SPEC_NAME
     # FROM_NEWEST指定了每次编译之前都要从yum上获取最新稳定版本进行安装到编译机上，所指定的包名为spec文件中BuildRequires的值才会工作。
     [ -n "$FROM_NEWEST" ] && echo "[ABS_INFO]$FROM_NEWEST are set to be updated from newest current-branch"
     "$ABS_PATH"abs_scripts/prepare.pl $WORKSPACE/${APP_NAME}/$SUB_DIR/rpm/${spec_file} $runid "$pkgAllow" "$FROM_NEWEST"
     # FROM_TEST的意义与FROM_NEWEST相仿，但每次是从test分支获取最新包。
     [ -n "$FROM_TEST" ] && "$ABS_PATH"abs_scripts/prepare_t.pl $WORKSPACE/${APP_NAME}/$SUB_DIR/rpm/${spec_file} "$FROM_TEST"  
     echo "[ABS_INFO]finish auto update the rpm package ${spec_file}"
#     cd rpm
     chmod 755 ${APP_NAME}-build*.sh
        
	# 调用rpm/下的build.sh脚本进行编译。
     ./${APP_NAME}-build.sh $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR ${APP_NAME} ${version} $ABS_BUILD_NUMBER
    #阿凡达还原环境
	if [ -n "$WALLE" ];then
	     echo "[ABS_INFO]Begin walle back the env to before"
	     sudo /usr/local/bin/walle -y  > $WORKSPACE/${APP_NAME}/walleback.log 2>&1
	     sudo yum install abs_c abs_git abs_java abs_daily -b current -y
	     rm ~/avatar.id
     fi
     find $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR -name "*.rpm"  -exec mv {} . \;
     #****
     # Warning: pls ensure that the package to be removed do exists in yum server.
     #****
     if [ -n "$DEL_AFTER" ];then
		DEL_AFTER=${DEL_AFTER//,/ }
   		echo "[ABS_INFO]$DEL_AFTER now to be remove from buildhost,since building end."		
	     for pkgtodel in $DEL_AFTER
	     do
		sudo rpm -e $pkgtodel --nodeps
		echo "[ABS_INFO]$pkgtodel is removed!"
	     done
     fi


     #****
     # Warning: pls ensure that the package to be removed do exists in yum server.
     #****
     if [ -n "$BACK_AFTER" ];then
 	BACK_AFTER=${BACK_AFTER//,/ }
   	echo "[ABS_INFO]---$BACK_AFTER now to be history back from buildhost,since building end."		
	     for pkgtodel in $BACK_AFTER
	     do
		    if [ ! -f ~/${pkgtodel}.pid ];then
			     my_back_after=${my_back_after//${pkgtodel}-[0-9]/}
			     continue
		    else
			     myid=$(cat ~/${pkgtodel}.pid)
			     if [ $myid != $runid ];then
				    my_back_after=${my_back_after//${pkgtodel}-[0-9]/}
				    continue
			    fi
		    fi 
		    sudo rpm -e $pkgtodel --nodeps
	     done

	     for pkgtoback in $my_back_after
	     do		
		     if [[ "$pkgtoback" =~ "^\." ]];then
			     continue
		     fi
		    sudo yum install $pkgtoback -b current -y
		    sudo yum install $pkgtoback -b test -y
		    [ $? == 0 ] && echo "[ABS_INFO]---------- $pkgtoback be back now!"
	     done
     fi
     #***
     # unlock the buildhost
     #****
     for name in `cat ~/${runid}.id`
     do
	     rm ~/${name}.pid
     done
     rm ~/${runid}.id 2>null


     getNewRpm
     echo "D" >${APP_NAME}-stauts.txt
     echo Private Building ended,the target rpm package is: ${JOB_URL}ws/${APP_NAME}/$SUB_DIR/rpm/$plat/${APP_NAME}-${version}*.rpm"--"`date "+%Y%m%d %H:%M:%S" ` >>${LOGFILE}
     test -e *.rpm 2>null
     exit_code=$?
 
			
				Dochangelist d
				# 如果AUTO_REVIEW的值为真，则调用post_review.sh发起代码review（和reviewborad集成）
				[ "$AUTO_REVIEW" == "true" ] && sh  "$ABS_PATH"abs_scripts/post_review.sh "$RB_PATTERN" "$rev0" || true
				if [ "$rv_error" == "true" ];then
					warnEmail "$adminEmail" "${APP_NAME} reviewboard error!  Cann't send a request for code review on $BUILD_NUMBER." "  ${APP_NAME} error found."
				fi
				echo "[ABS_INFO]exit code:$exit_code"
				[ $exit_code != 1 ] && true
    ;;
  TEST-BUILDING)
  # 本段负责将rpm包上传到yum服务器的test分支，并打release标签。支持运行自定义的rpm/${job_name}-buildqa.sh脚本
    if  [ $2 = $3 ]; then
		if [ "$BRANCH_MOD" == "true" ];then
			if [ -n $5 ];then
				SUB_DIR=$5
			else
				SUB_DIR=$SUFFIX
			fi
		fi
           cd $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR/rpm/
           export ABS_STATUS=`cat ${APP_NAME}-stauts.txt`
           if [ $ABS_STATUS == "R" ]
           then
                  echo "[Error]:You have only done Release-Building,cann't do Test-Building, Pls do Private-Building first!"
                  exit 3
           fi
	   #检查dev build是否成功，如果rpm目录存在*.rpm文件则进行，否则退出
	   t_rpm_e=$(ls *.rpm | wc -l)
	   if [ "$t_rpm_e" == 0 ];then
		   echo "[Error]:*.rpm files not found within rpm/! Is the Private-Building done and successfull?"
		   exit 3
	   fi	   
	   ##############
           echo "test-building begin"
	   #如果第四个传入参数为1，则调用个性化buildqa.sh脚本。
           if [ $4 == 1 ]
           then
 		version=$(getVersion)
        	buildno=`cat BUILDNO.txt`
		sh $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR/rpm/${APP_NAME}-buildqa.sh $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR ${APP_NAME} ${version} ${buildno} $ABS_OS
           fi
	   getNewRpm
           DoDelivery A test tags $ABS_COMMENT
	   Dochangelist a
                 
	   echo "[ABS_INFO]exit code:$exit_code"
	   if [ "$exit_code" == 0 ];then
		   echo "[ABS_INFO]:upload success! you can remove it on: http://rpm.corp.taobao.com/find.php?t=yum&q=${APP_NAME}";
	   fi
	   exit $exit_code
   else
         echo "[Error]:wrong input test-building password!"
         exit 3
   fi
     ;;
  RELEASE-BUILDING)
  # 本段负责将rpm包上传到yum服务器的current分支，并打release标签。支持运行自定义的rpm/${job_name}-buildpe.sh脚本
    if  [ $2 = $3 ]; then
		if [ "$BRANCH_MOD" == "true" ];then
			if [ -n $5 ];then
				SUB_DIR=$5
			else
				SUB_DIR=$SUFFIX
			fi
		fi
           cd $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR/rpm/
           export ABS_STATUS=`cat ${APP_NAME}-stauts.txt`
           if [ $ABS_STATUS == "D" ]
           then
                  echo "[Error]:You have only done Private-Building,cann't do Release-Building, Pls do Test-Building first!"
                  exit 3
           fi
           export ABS_BRANCHES=`cat SVNSUFFIX.txt`
           if [[ "$ABS_BRANCHES" =~ .*branches.* ]] &&  [ "$ALLOW_BRANCH" != 1 ] 
           then
                  echo "[Error]:Branches can't do Release-Building, Only trunk can do the Release-Building!"
                  exit 3
           fi
	   if [[ "$ABS_BRANCHES" =~ .*merge/.* ]]  
           then
                  echo "[Error]:merge-branches can't do Release-Building, Only trunk can do the Release-Building!"
                  exit 3
           fi
           echo "release-building begin"
	   #如果第四个传入参数为1，则调用个性化buildpe.sh脚本。
           if [ $4 == 1 ]
           then
		   version=$(getVersion)
		   buildno=`cat BUILDNO.txt`
		   sh $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR/rpm/${APP_NAME}-buildpe.sh $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR ${APP_NAME} ${version} ${buildno} $ABS_OS
		   exit_code2=$?
           fi
	   rm  ${ABS_WORKSPACE}/rb_id.txt 2>null
	   getNewRpm
	   Dochangelist r
	   DoDelivery R current release $ABS_COMMENT
	   exit $exit_code
                 
    else
            echo "[ERROR]: wrong input release-building password!"
            exit 3
     fi
     ;;
 DAILY-BUILDING)
 					 echo "DAILY-BUILDING;;"
 		 ;;
*)
     echo "parameter not found"
     exit 2
     ;;
esac


