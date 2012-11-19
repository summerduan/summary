#!/bin/bash
#
# (C) 2007-2011 Alibaba Group Holding Limited
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

##for check

#${ABS_PATH}/abs_scripts/abs_java.sh ${TYPE} ${SVNURL} ${BUILDPASS} ${VER} ${REALPASS} ${IFREBUILD}

# 此脚本用于模式二，与模式一的abs_c.sh类似，更多请参阅abs_c.sh注释。


# buildmaster is the hostname of your hudson server
# 请修改为你hudson的实际hostname
export absmaster="build.example.com"

# yumserver is the hostname of your yum server (packages server)
#请修改为你yum服务器的实际hostname
yumserver="http://yum.example.com"

# 假设运行abs_c.sh的用户是abs用户，请修改为你的实际用户
# 注：同时本脚本假设了hudson安装在$buildmaster:/home/abs/.hudson/ 目录下
# 请搜索本脚本的'abs'关键字
export ABS_PATH="/home/abs/"

# 修改为你的svn用户名和密码,ABS将使用此用户密码访问你的svn
svnuser=" --username=XXX --password=***"

function getNewRpm()
{
	cd $ABS_WORKSPACE/${APP_NAME}/$SUB_DIR/rpm
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
	TMP_NAME=`echo ${JOB_NAME} |awk -F'/' '{print $1}'`
	scp ./abs_rpm.log ads@$absmaster:${ABS_PATH}/.hudson/jobs/${TMP_NAME}/builds/${BUILD_NUMBER}/
	scp ./shell_output.txt ads@$absmaster:${ABS_PATH}/.hudson/jobs/${TMP_NAME}/builds/${BUILD_NUMBER}/
}
function getVersion()
{
   cd $ABS_WORKSPACE/${APP_NAME}/rpm
   if [ -e ${APP_NAME}-VER.txt ]
   then
	version=`cat ${APP_NAME}-VER.txt`
   else
	version=`cat ${APP_NAME}.spec|grep ^Version|cut -d ":" -f 2|sed "s/^ //g"` 
   fi
   echo $version
}

function inputVersion()
{
   cd $ABS_WORKSPACE/${APP_NAME}/rpm
   if [ -e ${APP_NAME}-VER.txt ]
   then
	echo $1 > ${APP_NAME}-VER.txt
   else
 	sed -i  "s/^Version:.*$/Version:"$1"/"  `pwd ${APP_NAME}.spec`/${APP_NAME}.spec 
   fi
}
function svnversion()
{
	myv=`svn log $1 --limit 1 -q $svnuser | grep "r" | awk -F' ' '{print $1}'`
}
function Dochangelist()
{
cd $ABS_WORKSPACE/${APP_NAME}
	svnurl1=`cat ${ABS_WORKSPACE}/${APP_NAME}/rpm/SVNPREFIX.txt`
  svnurl2=`cat ${ABS_WORKSPACE}/${APP_NAME}/rpm/SVNSUFFIX.txt`
  if [ -e "${ABS_WORKSPACE}/${APP_NAME}-$1-rev2.txt" ]
  then
		echo "${ABS_WORKSPACE}/${APP_NAME}-$1-rev2.txt exist"
		export rev1=`cat ${ABS_WORKSPACE}/${APP_NAME}-$1-rev2.txt`
	else
		echo "${ABS_WORKSPACE}/${APP_NAME}-$1-rev2.txt doesn't exist"
		export rev1=`svn info 2>null|grep -E "Revision:|^版本:" |awk -F':' '{print $2}'`
  fi
  
		export rev2=`svn info 2>null|grep -E "Revision:|^版本:" |awk -F':' '{print $2}'`
		echo rev2 is:  $rev2
		echo $rev2 >${ABS_WORKSPACE}/${APP_NAME}-$1-rev2.txt
		export rev0=`echo  $rev1|tr -d ' '`
		export rev=`echo  $rev2|tr -d ' '`
		echo "svn log -v --xml -r $rev0:$rev $svnurl1$svnurl2>${ABS_WORKSPACE}/$1-changelog.xml"
		svn log -v --xml -r $rev0:$rev $svnurl1$svnurl2>${ABS_WORKSPACE}/$1-changelog.xml
		export TMP_NAME=`echo ${JOB_NAME} |awk -F'/' '{print $1}'`
		scp ${ABS_WORKSPACE}/$1-changelog.xml ads@$absmaster:${ABS_PATH}/.hudson/jobs/${TMP_NAME}/builds/${BUILD_NUMBER}/changelog.xml

		if [ $1 == "a" ]
		then
			echo "Begin to do dba-review!"
			cd ${ABS_WORKSPACE}/${APP_NAME}
			[ -z "$RB_PATTERN" ] && RB_PATTERN="*sqlmap*.xml"
			[ "$AUTO_REVIEW" == "true" ] && sh  "$ABS_PATH"abs_scripts/merge_post_review.sh "$RB_PATTERN" "$rev0"
			echo "End to do dba-review!" 	
		else
			rm  ${ABS_WORKSPACE}/rb_id.txt 2>null
		fi
}

function DoDelivery()
{
        cd $ABS_WORKSPACE/${APP_NAME}/rpm
        echo "$1" >${APP_NAME}-stauts.txt
        version=$(getVersion)
	tag=${version//./_}
	mydate=`date "+%Y%m%d" `
        tag1=${APP_NAME}_$1_$tag_$mydate
        echo tag1: "$tag1"
        #buildno=${BUILD_NUMBER}
	buildno=`cat BUILDNO.txt`
        tagname="$tag1"_${buildno} #只有release才打tag，用当前的BUILD_NUMBER
        echo tagname:$tagname
        #cd ..
        export ABS_URL=`cat SVNPREFIX.txt`
        echo ABS_URL is $ABS_URL

	if [ $3 == "release" ]
	then
		TAG_URL=$ABS_URL"$3"
		#`echo $ABS_URL |sed -e "s/trunk/tags/"`
		echo TAG_URL is: $TAG_URL'/'$tagname
		cd ..
		svn copy . $TAG_URL'/'$tagname -m $2"-Building-$4- `date "+%Y%m%d %H:%M:%S" ` " $svnuser  --non-interactive 
		cd rpm
	fi
        
        temp_name=`cat /etc/rpm/macros|awk '{if($1=="%dist") print $2}'`
        echo RPM_NAME is ${APP_NAME}-${version}-${buildno}${temp_name}.${plat}.rpm

		cd $ABS_WORKSPACE/${APP_NAME}/rpm
	t_pk_array=(${APP_NAME})
	if [ -n "$MULTI_PK" ];then
		t_pk_l=${MULTI_PK//,/ }
		[ -z "$t_pk_l" ] && t_pk_l=${APP_NAME}
		t_pk_array=($t_pk_l)
	fi
	for pk_name in ${t_pk_array[*]}
	do
	  if [[ `echo ls *.rpm ` =~ "\.noarch\." ]]
	  then
		if [ $1 == "A" ]
		then
			if [ ! -e ${pk_name}-${version}-${buildno}*.rpm ];then
				echo "Error: ${pk_name}-${version}-${buildno}*.rpm do not exists!"
				exit 3
			fi
	        	yum-upload ${pk_name}-${version}-${buildno}*.rpm  --osver $ABS_OS --arch noarch --group yum --batch
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
			if [ "$SELF_RELEASE" == 1 ];then
				yum-upload ${pk_name}-${version}-${buildno}*.rpm  --osver $ABS_OS --arch noarch --group yum --batch
			fi
		        yum-setbranch  ${pk_name}-${version}-${buildno} $ABS_OS noarch current
			exit_code=$?
			if [ "$NOOS" == 1 ] 
			then
			  if [ "$ABS_OS" == 4 ]
			  then
				[ "$SELF_RELEASE" == 1 ] && yum-upload ${pk_name}-${version}-${buildno}*.rpm  --osver 5 --arch noarch --group yum --batch
				yum-setbranch  ${pk_name}-${version}-${buildno} 5 noarch current
			  else
				[ "$SELF_RELEASE" == 1 ] && yum-upload ${pk_name}-${version}-${buildno}*.rpm  --osver 4 --arch noarch --group yum --batch
			       	yum-setbranch  ${pk_name}-${version}-${buildno} 4 noarch current
			  fi
			  exit_code=$?
		        fi			
			[ "$SELF_RELEASE" == 1 ] && exit_code=${exit_code2}

		fi
	  else
		if [ $1 == "A" ]
		then
		        yum-upload ${pk_name}-${version}-${buildno}*.rpm  --osver $ABS_OS --arch ${plat} --group yum --batch
			if [ ! -f ${pk_name}-${version}-${buildno}*.rpm ];then
				echo "Error: ${pk_name}-${version}-${buildno}*.rpm do not exists!"
				exit 3
			fi
		else
			if [ "$SELF_RELEASE" == 1 ];then
				 yum-upload ${pk_name}-${version}-${buildno}*.rpm  --osver $ABS_OS --arch ${plat} --group yum --batch
			fi       
			yum-setbranch  ${pk_name}-${version}-${buildno} $ABS_OS ${plat} current
		fi
		exit_code=$?
		[ "$SELF_RELEASE" == 1 ] && exit_code=${exit_code2}
	  fi
      done
        echo "$2 Building--Target RPM URL is: $yumserver/cgi-bin/yuminfo?name=${APP_NAME}--RPMNAME: ${APP_NAME}-${version}-${buildno}${temp_name}.${plat}.rpm--$tagname--"`date '+%Y%m%d %H:%M:%S' ` >>${LOGFILE}
}


function getconflicts()
{
	for name in `svn st|grep '^[ ]*C' | awk '{print $2}'`
			do
				svn resolved $name > null 
				fn=$(basename $name)
				mydir=${name%$fn}
				mkdir -p abs_tmp_c/$mydir
				cp $name abs_tmp_c/$mydir
	done
	export CONFL_URL="merge"/$APP_NAME"_C_"`date +%Y%m%d`"_"$BUILD_NUMBER
	echo "Found some conflicts! Pls resolve them in the following url:"
	echo $PREFIX$CONFL_URL | tee ${ABS_WORKSPACE}/${APP_NAME}-confl.txt
	svn import abs_tmp_c/ $PREFIX$CONFL_URL -m "conflicts of merge from ABS_auto_merge" $svnuser  --non-interactive > null 
	echo "merge_conflict">${ABS_WORKSPACE}/${APP_NAME}-merge1.txt
}

function recordstatus()
{
		echo $PREFIX >SVNPREFIX.txt
		echo $suffix >SVNTRUNK.txt
		echo "branches/"$tmppath >SVNSUFFIX.txt
}

if [ $# -lt 1 ]
   then
      echo "Usage:abs_java_new.sh <MERGE-SOURCE|MERGE-BUILDING|RELEASE-BUILDING>"
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


ABS_COMMENT="Auto Build System-"
target=1

mylang='C'
[ -n "$MYLANG" ] && mylang=$MYLANG
LANG=$mylang
export LANG

TEMP=`getopt -o p:r:t:s:h -- "$@"`
eval set -- "$TEMP"
suffix='trunk'
while true ; do
  case "$1" in
    -h) usage; shift ;;
    -p) APP_NAME=$2; shift 2 ;;
    -r) ABS_COMMENT=$2; shift 2 ;;
    -t) target=$2; shift 2 ;;
    -s) suffix=$2; shift 2 ;;
    --) shift; break;;
    *) echo "Internal error!"; exit 1;;
  esac
done


export ABS_WORKSPACE=$WORKSPACE
if [  -d $ABS_WORKSPACE ];then
	echo ""
else
	echo "[ERROR]: the workspace $ABS_WORKSPACE do not exists!"
	exit 1
fi
export ABS_BUILD_NUMBER=$BUILD_NUMBER
#export ABS_COMMENT="Auto Build System-"

echo ABS_WORKSPACE is:$ABS_WORKSPACE
echo ABS_BUILD_NUMBER is : $ABS_BUILD_NUMBER
echo Build_Server_Plat is: $plat
echo APP_NAME is: $APP_NAME

export ABS_OS=`cat /etc/redhat-release |awk '{print $7}'|awk -F'.' '{print $1}'`
echo ABS_OS is $ABS_OS

if [ -f "${ABS_WORKSPACE}/${APP_NAME}-merge1.txt" ]
then
	export M_STATUS=`cat ${APP_NAME}-merge1.txt`
	echo "The Merge status is :  "$M_STATUS
else
	echo "The first time for merge" > ${ABS_WORKSPACE}/${APP_NAME}-merge1.txt
fi
#`date +%Y%m%d`
LOGFILE="$ABS_PATH/abs_logs/$APP_NAME.log"
ln -s -f "$ABS_PATH"abs_logs/${APP_NAME}.log $ABS_WORKSPACE/${APP_NAME}.log


case $1 in
  MERGE-SOURCE)

  #-------
  # 此段根据用户输入的svn分支路径，合并代码到trunk中，检测是否存在冲突
  #-------
     if [ "$M_STATUS" == "trunk_conflict" ]
     then
          echo "Cannot merge source,you should resolve them first,Only RELEASE-BUILDING can be done!"
          exit 2
     fi
     if [ "$M_STATUS" == "pe_lock" ]
     then
          echo "Cannot merge source,you should do it after pe_unlock trunk privildge!"
          exit 2
     fi
     if [ "$M_STATUS"  == "merge_building_success" ] && [ "$IF_REDO" == false]
     then
          echo "Cannot do this,you should release to PE first,unless you choose IF_REDO!"
          exit 2
     fi
	echo "merge from sources: $3"
    	cd $ABS_WORKSPACE
     if [ -f "${ABS_WORKSPACE}/ABS_COMMENT.txt" ]
     then
				export TMP_COMMENT=`cat ${ABS_WORKSPACE}/ABS_COMMENT.txt`
				TMP_COMMENT="$TMP_COMMENT$ABS_COMMENT"
				echo "$ABS_COMMENT" >${ABS_WORKSPACE}/ABS_COMMENT.txt
				echo "The TMP_COMMENT is :  "$TMP_COMMENT
     else
				TMP_COMMENT="$ABS_COMMENT"
     fi    
     if [ "$MULTI_MERGE" != "true" ]
     then
       TMP_COMMENT=$ABS_COMMENT
       [ -d "${ABS_WORKSPACE}" ] && rm -rf $ABS_WORKSPACE/${APP_NAME}
       echo "rm -rf $ABS_WORKSPACE is done"
       cd $ABS_WORKSPACE
       echo svn checkouting ....
       svn checkout $2"/$suffix/" ${APP_NAME} $svnuser --non-interactive > svnco.log
       tail -n 1 svnco.log          
     else
       if [ -e "${ABS_WORKSPACE}/${APP_NAME}" ]
       then 
           cd $ABS_WORKSPACE/${APP_NAME}
	   svn up $svnuser  --non-interactive >> svnco.log
       	   tail -n 1 svnco.log
   	else
           echo "Directory:" $ABS_WORKSPACE/${APP_NAME} " is not exists!"
           cd $ABS_WORKSPACE
           echo svn checkouting ....
           svn checkout $2"/$suffix/" ${APP_NAME} $svnuser  --non-interactive > svnco.log
           tail -n 1 svnco.log
			#echo "The first time for merge" > ${ABS_WORKSPACE}/${APP_NAME}-merge1.txt
           echo "$ABS_WORKSPACE is created!"
   	fi
     fi
     cd $ABS_WORKSPACE/${APP_NAME}
	
     if [ ${RANGE} = 0 ]
     then
		svn merge $3 $svnuser  --non-interactive  > $ABS_WORKSPACE/svnmerge.log
     else
	     RANGE=${RANGE/-/:}
		svn merge $3 -r ${RANGE} $svnuser  --non-interactive  > $ABS_WORKSPACE/svnmerge.log
     fi
     cd rpm/
     	svn revert *
	svn resolved ./*
	cd ..
	svn st|grep '^[ ]*C'
	 if [ $? == 1 ] ;then
		echo "no conflict!"
    		export mergeurl="merge/"$APP_NAME"_M_"`date +%Y%m%d`"_"$BUILD_NUMBER
    		echo $2$mergeurl>${ABS_WORKSPACE}/${APP_NAME}/mergeurl.log
		echo "merge_success">${ABS_WORKSPACE}/${APP_NAME}-merge1.txt
                echo "merge comments is: "$TMP_COMMENT
		echo "svn status is: "
		svn st
		[ -z "$TMP_COMMENT" ] && TMP_COMMENT="merge from $3"
		svn copy . $2$mergeurl -m "$TMP_COMMENT" $svnuser  --non-interactive 
		#svn rm $2"merge/"$APP_NAME"_codereview_"${BUILD_NUMBER} -m "$TMP_COMMENT$tmpst" $svnuser  --non-interactive 
		echo "Merge successful! The merge url is:"
	       	echo "$2$mergeurl"
		echo "MERGE-SOURCE successed--------"$2$mergeurl`date "+%Y%m%d %H:%M:%S" ` >>${LOGFILE}
		svnversion "$2$mergeurl"
		echo $myv >${ABS_WORKSPACE}/${APP_NAME}/rpm/mergeversion.txt
	 else
		 PREFIX=$2
		getconflicts
    	
	
		echo "merge comments is: "$TMP_COMMENT
#		svn rm ${2}$CONFL_URL -m"delete the conflict dir before new conflicts"		
		echo "MERGE-SOURCE conflicted--------"$2$CONFL_URL`date "+%Y%m%d %H:%M:%S" ` >>${LOGFILE}
		cd $ABS_WORKSPACE/${APP_NAME}/rpm 
		tmppath=`echo $3 | awk -F 'branches' '{print $2}'`
		recordstatus
		exit 2
	fi
		 
     cd $ABS_WORKSPACE/${APP_NAME}/rpm 
     PREFIX=$2
     tmppath=`echo $3 | awk -F 'branches' '{print $2}'`
     recordstatus
    ;;    
CONFILCT_RESOLVED)

   #-----------
   # 当用户解决冲突时，调用此段函数，告诉ABS冲突已解决，ABS将解决掉的文件覆盖到本地workspace，并检测是否已经解决干净。
   #-----------
	echo "CONFILCT_RESOLVED,SUFFIX is para"
	confurl=`cat ${ABS_WORKSPACE}/${APP_NAME}-confl.txt`
	tmpst2=`cat ${ABS_WORKSPACE}/${APP_NAME}-merge1.txt`
	cd $ABS_WORKSPACE/${APP_NAME}
	if [ ${tmpst2} = "merge_conflict" ]
	then
          tmpstr1=`cat $ABS_WORKSPACE/${APP_NAME}/rpm/SVNSUFFIX.txt`
	       if [ -d abs_tmp_c ];then
		       rm -rf abs_tmp_c
	       fi
       		svn export $confurl ./abs_tmp_c --force $svnuser  --non-interactive > null 
		grep ">>>>>>>" -r ./abs_tmp_c/*
		if [ $? == 0 ];then
			echo "Error: some conflicts still found! Please resolve all of them. "
			exit 2
		fi	
     		cp -r  ./abs_tmp_c/* ./
		rm -r  ./abs_tmp_c
		svn rm  $confurl -m"delete the conficts data,since they has been resolved" $svnuser  --non-interactive 
		echo "conflict resolved! Confurl is removed."
		echo "The result of 'svn status':"
		svn st|grep -v '?'
		export mergeurl="merge/"$APP_NAME"_M_"`date +%Y%m%d`"_"$BUILD_NUMBER
		PREFIX=`cat $ABS_WORKSPACE/${APP_NAME}/rpm/SVNPREFIX.txt`
    		echo $PREFIX$mergeurl>${ABS_WORKSPACE}/${APP_NAME}/mergeurl.log
		svn copy . $PREFIX$mergeurl -m "merge from $tmpstr1" $svnuser  --non-interactive 
		echo "The merge url is:"$PREFIX$mergeurl
		echo "CONFILCT_RESOLVED!"
     		echo "merge_success">${ABS_WORKSPACE}/${APP_NAME}-merge1.txt
		svnversion "$PREFIX$mergeurl"
		echo $myv >${ABS_WORKSPACE}/${APP_NAME}/rpm/mergeversion.txt
        else
					echo "No CONFILCT FILES!"
					exit 0
       fi
     ;;
MERGE-BUILDING)
   #-------------
   # 此段对merge后的合并结果进行编译、打包，并上传到test分支供测试。
   #-------------
    echo "MERGE-BUILDING begin now"
    brflag="false"
    cd $ABS_WORKSPACE/${APP_NAME}
	tmpst2=`cat ${ABS_WORKSPACE}/${APP_NAME}-merge1.txt`
	if [ ${tmpst2} = "merge_conflict" ]
	then
		echo "Error: You must be resolved the conflicts first!"
		exit 2
	fi
	PREFIX=`cat $ABS_WORKSPACE/${APP_NAME}/rpm/SVNPREFIX.txt`
	echo PREFIX is: ${PREFIX}
	[ -z "$suffix" ] && suffix=$(cat $ABS_WORKSPACE/${APP_NAME}/rpm/SVNTRUNK.txt)
	if [ -n "${RESET_MERGEURL}" ];then
		if [[ "${RESET_MERGEURL}" =~ branches/ ]];then
			tmppath=`echo ${RESET_MERGEURL} | awk -F 'branches/' '{print $2}'`
			brurl="${PREFIX}/branches/$tmppath"	
			cd $ABS_WORKSPACE
		       	[ -d "${ABS_WORKSPACE}" ] && rm -rf $ABS_WORKSPACE/${APP_NAME}/                    
		    echo "You choose branche building. svn checkouting ...."
		    svn checkout $brurl ${APP_NAME} $svnuser  --non-interactive > svnco.log
		    tail -n 1 svnco.log		    
		    brflag="true"
		    cd $ABS_WORKSPACE/${APP_NAME}/rpm
		    recordstatus
	    	else
			cd $ABS_WORKSPACE
			mergeurl="${RESET_MERGEURL}"
		       	[ -d "${ABS_WORKSPACE}" ] && rm -rf $ABS_WORKSPACE/${APP_NAME}/
		       	svn checkout $PREFIX"/$suffix/" ${APP_NAME} $svnuser  --non-interactive > svnco.log
			if [ ${tmpst2} != "merge_ict" ];then
			       	svn merge $mergeurl $svnuser  --non-interactive  
			fi
			echo $mergeurl>${ABS_WORKSPACE}/${APP_NAME}/mergeurl.log
			cd $ABS_WORKSPACE/${APP_NAME}/rpm
		    	recordstatus
			echo $mergeurl >SVNSUFFIX.txt
		fi
	else
		mergeurl=$(cat ${ABS_WORKSPACE}/${APP_NAME}/mergeurl.log)
		if [ ${tmpst2} != "merge_success" ];then
			svn merge $mergeurl $svnuser  --non-interactive  
		fi	
	fi
	echo "Building on $mergeurl$brurl now."
	cd $ABS_WORKSPACE/${APP_NAME}
	svn st|grep '^[ ]*C'
	if [ $? == 0 ] ;then
		getconflicts
		exit 2
	fi
	svn st|awk '{print substr($0,7)}'|grep ^C | awk '{print $2}' | xargs svn resolved > null 2>&1

    export input=${PREFIX}"/$suffix/";
    svn_svr=`echo $input |awk -F'/' '{print $4}'`

      cd $ABS_WORKSPACE/${APP_NAME}/rpm
      if [ "${VER}" = 0 ]
      then
          echo "Use svn versionno"
          version=$(getVersion)
          echo $version
      elif [ "${VER}" = 1 ]
      then
	        version=$(getVersion)
          	if [[ "$version" =~ "([0-9]+.[0-9]+).([0-9]+)" ]]
		then
		          version2=`expr ${BASH_REMATCH[2]} + 1`
		          echo "svn versionno plus 1:"${BASH_REMATCH[1]}"."$version2
		          inputVersion ${BASH_REMATCH[1]}"."$version2 
		          version=$(getVersion)
		  fi
      else
          inputVersion ${VER} 
          echo "use the users input charater:"$VER
          version=${VER}
      fi
      if [[ "$version" =~ ^[0-9.-]+$ ]]
      then
        echo "match version format: " $BASH_REMATCH
        yum deplist ${APP_NAME}-$version -b current|grep -E "^package:"
        if [ $? -eq 0 ] &&  [ "$ALLOW_SAME" != 1 ]
        then
         echo The version ${APP_NAME}-$version is already exists at the YUM-package server! Please input another version number
            #echo "merge_qa_fail">${ABS_WORKSPACE}/${APP_NAME}-merge1.txt
            exit 1
        else
	    echo "ALLOW_SAME-allow same versions upload to yum_current status is: $ALLOW_SAME"
            echo "have no version as $BASH_REMATCH, your action is allowed to take"
        fi
     else
        echo "Error: input charactors ($version) are illegal version number."
        #echo "merge_qa_fail">${ABS_WORKSPACE}/${APP_NAME}-merge1.txt
        exit 1
     fi
###############
     svn commit ${APP_NAME}-VER.txt -m "ABS-Version Change `date "+%Y%m%d %H:%M:%S" ` " $svnuser  --non-interactive > NULL
     svn commit ${APP_NAME}.spec -m "ABS-Version Change `date "+%Y%m%d %H:%M:%S" ` " $svnuser  --non-interactive > NULL
     cd ..

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
     "$ABS_PATH"abs_scripts/prepare.pl $WORKSPACE/${APP_NAME}/rpm/${APP_NAME}.spec $runid 
     echo "auto update the rpm package ${APP_NAME}.spec"
     cd rpm
     chmod 755 ${APP_NAME}-build*.sh
     ./${APP_NAME}-build.sh $ABS_WORKSPACE/${APP_NAME} ${APP_NAME} ${version} $ABS_BUILD_NUMBER
     if [ ! x"$MAVEN_TYPE" == "x" ];then
	     [ x"$MAVEN_BUILD_TYPE" == "x" ] && MAVEN_BUILD_TYPE="T R"
	     for buildtype in $MAVEN_BUILD_TYPE
	     do
		   maven_build $buildtype
	     done

     fi
     find $ABS_WORKSPACE/${APP_NAME}/ -name "*.rpm"  -exec mv {} . \;
    #***
     # unlock the buildhost
     #****
     for name in `cat ~/${runid}.id`
     do
	     rm ~/${name}.pid
     done
     rm ~/${runid}.id 2>null
     getNewRpm
     echo MERGE-BUILDING ended,the target rpm package is: ${JOB_URL}ws/${APP_NAME}/rpm/$plat/${APP_NAME}-${version}*.rpm"--"`date "+%Y%m%d %H:%M:%S" ` >>${LOGFILE}
     echo $ABS_BUILD_NUMBER >BUILDNO.txt
	
	DoDelivery A test tags $ABS_COMMENT
	Dochangelist a

	cd $ABS_WORKSPACE/${APP_NAME}/rpm 
	release=$ABS_BUILD_NUMBER
     echo "merge_building_success">${ABS_WORKSPACE}"/"${APP_NAME}-merge1.txt
     if [ "$brflag" == "true" ];then
	     echo "branch_building_success">${ABS_WORKSPACE}"/"${APP_NAME}-merge1.txt
     fi
	exit $exit_code
     ;;
RELEASE-BUILDING)
#RELEASE-BUILDING ${BUILDPASS} ${REALPASS} ${IFREBUILD}
  #-----------
  # 此段对打好的代发布包上传到yum的current分支，供上线。
  #-----------

    echo "RELEASE-BUILDING begin!"
    if  [ $2 = $3 ]; then
           if [ $M_STATUS != "merge_building_success" ]&&[ $M_STATUS != "pe_lock" ]
           then
                  echo "only merge_building_success status/pe_lock can to do release,cann't do Release-Building, Pls do merge-building first!"
                  exit 3
           fi
           
     cd $ABS_WORKSPACE
     if [ -f "${ABS_WORKSPACE}/ABS_COMMENT.txt" ]
     then
				export TMP_COMMENT=`cat ${ABS_WORKSPACE}/ABS_COMMENT.txt`
				TMP_COMMENT="$TMP_COMMENT$ABS_COMMENT"
				echo "The TMP_COMMENT is :  "$TMP_COMMENT
     else
				TMP_COMMENT="$ABS_COMMENT"
     fi
    
	cd $ABS_WORKSPACE/${APP_NAME}/rpm

	echo "release-building begin"
	if [ "$SELF_RELEASE" == 1 ];then	
	     echo $ABS_BUILD_NUMBER >BUILDNO.txt
	fi
		version=$(getVersion)
		buildno=`cat BUILDNO.txt`
		PREFIX=`cat $ABS_WORKSPACE/${APP_NAME}/rpm/SVNPREFIX.txt`
		[ -z "$suffix" ] && suffix=$(cat $ABS_WORKSPACE/${APP_NAME}/rpm/SVNTRUNK.txt)
		export input=${PREFIX}"/$suffix/";
		scm_lib=`echo $input |awk -F'/' '{print $5}'`
		cd $ABS_WORKSPACE/${APP_NAME}/
		svn up   $svnuser  --non-interactive  #UED sourcecode
		mergeurl=$(cat ${ABS_WORKSPACE}/${APP_NAME}/mergeurl.log)
		[ -z "$TMP_COMMENT" ] && TMP_COMMENT="merge from $mergeurl"

			#如果有冲突，则退出
		svn st|grep '^[ ]*C'
		if [ $? == 1 ] ;then
			echo "no conflict!"
		else
		 	echo "pe_lock conflict"
		#	echo "comments is: "$TMP_COMMENT
		
			getconflicts
			exit 2
		fi					 		
		svn st|awk '{print substr($0,7)}'|grep ^C | awk '{print $2}' | xargs svn resolved > null
		if [ $4 == 1 ];then					 		
		 	sh $ABS_WORKSPACE/${APP_NAME}/rpm/${APP_NAME}-buildpe.sh $ABS_WORKSPACE/${APP_NAME} ${APP_NAME} ${version} $buildno
			if [ ! x"$MAVEN_TYPE" == "x" ];then
				cd rpm/
			     for buildtype in $MAVEN_BUILD_TYPE
			     do
				   maven_build $buildtype
			     done
			     DoDelivery A test tags $ABS_COMMENT
			     cd ../

			fi
			find $ABS_WORKSPACE/${APP_NAME}/ -name "*.rpm"  -exec mv {} ./rpm \;
			exit_code2=$?
		fi
	cd $ABS_WORKSPACE/${APP_NAME}/
	echo "[ABS_INFO]:Begin svn commit the results of merge to trunk!"
	svn commit -m "$TMP_COMMENT" $svnuser  --non-interactive 
	if [ $? == 1 ];then
		echo "[Error]: svn commit failed! ABS abort!"
		exit 1
	fi
	echo path is `pwd`
	cd $ABS_WORKSPACE/${APP_NAME}/rpm/
        Dochangelist r
        DoDelivery R current release $ABS_COMMENT
        
        echo "pe_lock">${ABS_WORKSPACE}/${APP_NAME}-merge1.txt
	if [ "$AUTODEL_BRANCHES" == "true" ];then
		branchurl=`cat ${ABS_WORKSPACE}/${APP_NAME}/rpm/SVNSUFFIX.txt`
		svn rm $PREFIX$branchurl -m"delete the branches since it merged to trunk" $svnuser  --non-interactive 
	fi
	#****delete the merge url****
	newv=$(cat ${ABS_WORKSPACE}/${APP_NAME}/rpm/mergeversion.txt)
	svnversion "$mergeurl"
	if [ "$newv" == "$myv" ];then
		svn rm $mergeurl -m"delete the merge url since it never changed"  $svnuser  --non-interactive 
	fi
	exit $exit_code
   else
        echo "wrong input release-building password!"
        exit 3
   fi
     ;;
PE-UNLOCK)
   #------
   # 标识此次发布周期已完成
   #------

     echo "PE-UNLOCK,Now UED can commit sourcecode to SVN!"
     echo "PE-UNLOCK,Now UED can commit sourcecode to SVN!"`date "+%Y%m%d %H:%M:%S" ` >>${LOGFILE}
     
     echo "pe_unlock">${ABS_WORKSPACE}/${APP_NAME}-merge1.txt
     echo "pe_unlock">${ABS_WORKSPACE}"/ABS_COMMENT.txt"
     ;;
*)
     echo "parameter not found"
     exit 2
     ;;
esac


