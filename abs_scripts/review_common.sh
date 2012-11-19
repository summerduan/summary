#!/bin/sh
[ -z "$RV_GROUP" ] && [ -z "$RV_USER" ] &&  para=" --target-groups=sql_review"
[ -n "$RV_GROUP" ] && para=" --target-groups=$RV_GROUP"
[ -n "$RV_USER" ] && para="$para --target-people=$RV_USER"
para="$para -p"
if [ -z $rev0 ]
then
	echo "Cann't get the version of last time. Post-review abort!"
	exit	
fi
cd ${ABS_WORKSPACE}/${APP_NAME}/${SUB_DIR}/
echo "" > ${ABS_WORKSPACE}/diff_files.log
if [ -f  ${ABS_WORKSPACE}/rb_id.txt ];then
	rid=`cat ${ABS_WORKSPACE}/rb_id.txt | awk -F':' '{print $1}' `
	rev_last=`cat ${ABS_WORKSPACE}/rb_rev.txt  `
	if [ -f ${ABS_WORKSPACE}/dev_reversion.ini ];then
		rev3=$(cat ${ABS_WORKSPACE}/dev_reversion.ini);
	fi
fi
if [ "$br_flag" == 1 ];then
	rev3=`svn log --stop-on-copy -q | tail -2 | head -1 |awk -F' ' '{print $1}'`
	rev3=${rev3/r/}
	rid=`cat ${ABS_WORKSPACE}/rb_id_${brn}.txt | awk -F':' '{print $1}' `
	rev_last=`cat ${ABS_WORKSPACE}/rb_rev_${brn}.txt | awk -F':' '{print $2}' `
fi
[ -z "$rev_last" ] && rev_last=$rev3
[ -n "$RV_ID" ] && rid=$RV_ID
if [[ "$rid" =~ ^[0-9]+$ ]];then
	rid_str=" -r $rid"
fi
