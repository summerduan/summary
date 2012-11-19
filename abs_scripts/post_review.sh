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
#   XueJiang  <xuejiang@taobao.com>
#

#  本脚本利用reviewboard客户端工具自动发起代码review请求。

# rev0 is the version of lastest dev build.

#请配置如下两个变量
absmaster="build.example.com"
[ 'x' == "x$ABS_PATH" ] && ABS_PATH="/home/abs"

pattern=$1
pattern=${pattern:-"sqlmap*.xml"}
rev0=$2
para=''

# to avoid multi post-review in multi-configuration project 
TMP_NAME=$(echo ${ABS_WORKSPACE} |  awk -F'/' '{print $6}')
scp ads@$absmaster:$ABS_PATH/.hudson/jobs/${TMP_NAME}/builds/${BUILD_NUMBER}/rb_exist.abs.txt ./ 2>null
if [ -f rb_exist.abs.txt ];then	
	rm rb_exist.abs.txt
	exit
fi
echo 1 > ./rb_exist.abs.txt
scp ./rb_exist.abs.txt ads@$absmaster:$ABS_PATH/.hudson/jobs/${TMP_NAME}/builds/${BUILD_NUMBER}/ 
rm ./rb_exist.abs.txt
#end of multi cooprate

rev3=$rev0
source $ABS_PATH/abs_scripts/review_common.sh

function getpwd()
{
	mytree=(${1//\// })
	yourtree=(${2//\// })
	local count=${#mytree[@]}
	local j=-1
	while [ "$j" -lt "$count" ]
	do
		let "j = $j + 1"		
		if [ "${mytree[$j]}" == "${yourtree[$j]}" ]
		then
			unset mytree[$j]
			unset yourtree[$j]
			continue
		fi
		let "mydeep=$count - $j"
		break
	done
	local ii=1
	pdir=''
	[ "$mydeep" -eq "0" ] && pdir='./'
	while [ "$ii" -le "$mydeep" ]
	do
		pdir="../$pdir"
		let "ii = $ii + 1"
	done
	yourpwd=''
	for d in ${yourtree[*]}
	do
		yourpwd="$yourpwd/$d"
	done
	yourpwd="$pdir$yourpwd"
					
}
basefile=''
basedir=''
OLD_LANG=$LANG
export LANG=C
tmp_pattern=${pattern//\*/.\*}
svnroot=$(svn info ${ABS_WORKSPACE}/${APP_NAME}/${SUB_DIR}/ | grep -E "Repository Root:|版本库根:" | awk -F': ' '{print $2}')
svnurl=$(svn info ${ABS_WORKSPACE}/${APP_NAME}/${SUB_DIR}/ | grep  "URL:" | awk -F'URL: ' '{print $2}')
strlen1=$(echo $svnurl| wc -c)
toppath=${svnurl/$svnroot/}
strlen2=$(echo $toppath | wc -c)
if [ $strlen1 -eq $strlen2 ];then
	echo "svn url replace failed! Cann't locate the current path! Pls tell xuejiang! error:$svnurl == $toppath"
	exit
fi
rev2=`svn info ${ABS_WORKSPACE}/${APP_NAME}/${SUB_DIR}/${RV_DIR} 2>null|grep -E "Revision:|^版本:"  |awk -F':' '{print $2}'`
rev_end='head'
[ -n "$SVN_REVISION_END" ] && rev_end=$SVN_REVISION_END
for name in `svn log  ${ABS_WORKSPACE}/${APP_NAME}/${SUB_DIR}/${RV_DIR} -v -r${rev_last}:${rev_end}  | grep -E " M | A | R " | awk -F' ' '{print $2}' | grep -E "${tmp_pattern}$"`
do
  #v=`svn info $name 2>null | grep Revision |awk -F':' '{print $2}'`
  name=${name/$toppath/}
  name=${ABS_WORKSPACE}/${APP_NAME}/${SUB_DIR}$name
  if [ -f $name.diff ];then
	  continue;
  fi
  if [ -d $name ];then
	  continue;
  fi
  info=`svn log -q $name --limit=1 2>null | grep "^r" `
  v=`echo $info | awk -F' ' '{print $1}'`
  v=${v/r/}
  u=`echo $info | awk -F'|' '{print $2}'`
  u=${u// /}
  [ -n "$SVN_REVISION_END" ] && v=$SVN_REVISION_END
  if [[ ! "$v" =~ ^[0-9]+$ ]]
  then
	 # echo "$v is not a version number with $name!"
	  [ "$v" != "head" ] && continue
  fi
  [ "$v" -le "${rev_last}" ] && continue
  if [ -z "$basefile" ] 
  then
	basefile=$name
	dir=${name##/*/}
	dir=${name%$dir}
	basedir=$dir
  	cd $dir
  	myname=${name/$dir/}
 	svn diff -r$rev3:$v $myname --config-option config:helpers:diff-cmd=diff > $name.diff
	filesize=$(cat $name.diff | wc -c)
	if [ $filesize -lt 2 ]
	then
		cp $name $name.add
		svn add $name.add 2&>null
		svn diff $myname.add --config-option config:helpers:diff-cmd=diff > $name.diff
		svn revert $name.add 2&>null
		rm $name.add
	fi
  else
	getpwd $basedir $name
	svn diff -r$rev3:$v $yourpwd --config-option config:helpers:diff-cmd=diff > $name.diff
	filesize=$(cat $name.diff | wc -c)
	if [ $filesize -lt 2 ]
	then
		cp $name $name.add
		svn add $name.add 2&>null
		svn diff $yourpwd.add --config-option config:helpers:diff-cmd=diff > $name.diff
		svn revert $name.add 2&>null
		rm $name.add
	fi
	cat $name.diff >> $basefile.diff
  fi
  echo "$name" >> ${ABS_WORKSPACE}/diff_files.log
done
export LANG=${OLD_LANG}
diff_files=" `cat ${ABS_WORKSPACE}/diff_files.log`"
source $ABS_PATH/abs_scripts/review_common_bottom.sh
