#!/bin/sh
if [ -z "$basefile" ] 
then
	echo "No files changes found with pattern $pattern!"
	exit	
else
	echo "found thoses files has changed with pattern $pattern:$diff_files"
  	cd $basedir  	
	[ -n "$CALLER" ] && u=$CALLER
	submittor="--submit-as=$u"
	if [ -n "$rid_str" ];then
		submittor=""
	fi
	echo "post-review --diff-filename=$basefile.diff $para $rid_str $submittor "
	# 注： post-review 是reviewboard的客户端命令
	post-review --diff-filename=$basefile.diff $para $rid_str $submittor  --summary="${APP_NAME},$pattern has been changed! Pls review. thx" | tee ./abs_tmp.log
	if [ $? != 0 ];then
		export rv_error='true';
	else
		if [ "$br_flag" == 1 ];then
			echo "$rev2" >  ${ABS_WORKSPACE}/rb_rev_${brn}.txt
		else
			echo "$rev2" >  ${ABS_WORKSPACE}/rb_rev.txt		
		fi
	fi
	# if it's a new request,then
	if [ -z "$rid_str" ];then
		rid=$(tail -1 ./abs_tmp.log | awk -F'/r/' '{print $2}')
		if [ "$br_flag" == 1 ];then
			echo "$rid" >  ${ABS_WORKSPACE}/rb_id_${brn}.txt
		else
			echo "$rid" >  ${ABS_WORKSPACE}/rb_id.txt		
		fi
		echo $rev0 > ${ABS_WORKSPACE}/dev_reversion.ini
	fi
					
fi
