#!/usr/bin/env perl
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


# 本脚本依据spec文件的BuildRequires要求从yum上安装包到编译机上。
use strict;
use warnings;

open (FILE,"< $ARGV[0]") || die("File cant open");
# $apkg，参数2，允许自动降版本号的包列表。此限制是为了避免卸载系统包。须在buildRequires中方有效。
my $runid = $ARGV[1];
my $apkg = $ARGV[2];
# 参数3，总是从yum上获取最新版本进行安装的包列表。即使编译机上已满足条件，仍然试图获取最新的包进行安装。须在BuildRequires中方有效。

my $in = $ARGV[3];
my $times = 0;
my @npkg = split(/;|,| /,$in);
sub greater($$)
{
  my($ver1,$ver2)=@_;
  my @va1=split(/\./,$ver1);
  my @va2=split(/\./,$ver2);
  my $n = scalar @va1;
  my $i;
  for($i=0;$i<$n;$i++)
  {
	  return 0 if(! defined $va2[$i]) ;
	  return 1 if ($va1[$i] > $va2[$i]);
	  return 0 if ($va1[$i] < $va2[$i]);
  }
  return 0;

}
while (<FILE>) {
    if (/^ \s* BuildRequires \s* : \s* (.+)/x) {
        my $prereqs = $1;
        for ($prereqs) {
            while (1) {
                my ($pkg, $op, $ver);
                if (m{
                        \G \s* (\S+) \s* (>=|>|<|<=|=) \s*
                        ([\d\._-]+) (?:\s* , \s*)?
                    }xgc) {
                    ($pkg, $op, $ver) = ($1, $2, $3);
                } elsif (m{ \G \s* (\S+) (?:\s* , \s*)? }xgc)  {
                    $pkg = $1;
                } elsif (m{ \G . }) {
                    die "Syntax error: $&\n";
                } else {
                    last;
                }
                if ( !$op || !$ver ){
                        $op = ">=";
                        $ver = "";
                }
		$pkg =~ s/,/ /g;
		$pkg =~ s/[\n\r]//;
		while( -e "/home/ads/${pkg}.pid" )
		{  
			my $myid=`cat /home/ads/$pkg.pid`;
			$myid=~ s/[\r\n]//;
			last if("$myid" eq "$runid");
			print "another job is running,waiting for a moment!$pkg locked to change.\n";
		    	sleep 5; 
			$times = $times + 1;
			die("waiting too long time, fail to update BuildRequires!")if( $times >= 100);
		}
		`echo $runid > /home/ads/${pkg}.pid`;
		`echo ${pkg} >> /home/ads/$runid.id`;
		my $now_v=`rpm -qv $pkg|sed 's/$pkg-//'`;
		$now_v =~ /(.+)-.*/;
		$now_v = $1;
		if($1 !~ /^[0-9.-]+$/)		
		{
			$now_v = "";
		}
#                warn "Package($pkg), Op($op), Ver($ver)\n";
                if ($op =~ />=/){
			my @result = grep(/^$pkg$/, @npkg);
			if(greater($ver,$now_v) || (@result >= 1) || ($now_v eq "")){
                                print "the $pkg current version: $now_v is set to be updated!\n";
				my $flag=1;
				if( -e "/home/ads/abs_scripts/pkg_top.txt" )
				{
				  my $toppkg=`cat /home/ads/abs_scripts/pkg_top.txt| grep "$pkg "`;
				  if (  "$toppkg" ne "")
				  {
				        my @myarr = split(/=/,$toppkg);
				        $myarr[0] =~ s/ //g;
				        $myarr[1] =~ s/[ \r\n]//g;
				        my $pkgv="$myarr[0]-$myarr[1]";
					if(greater($ver,$myarr[1]))
					{
						$pkgv=$pkg;
					}else
					{	
						print "The package is touch the ceiling:$pkgv\n";	
					}
					system("sudo yum install $pkgv -b stable -y");
					system("sudo yum install $pkgv -b current -y");
					$flag=0;
				  }
				}
				if($flag){
					system("sudo yum install $pkg -b stable -y");
					system("sudo yum install $pkg -b current -y");
				}
			}
                } elsif ($op =~ /=/ || $op =~ /<=/){
                        #print "sudo yum list installed|grep $pkg|awk '{print $2}'|grep -v -E \"branch|Packages\"\n";
                       print "sudo yum install -b current -y $pkg-$ver\n";
			if ($pkg =~ /$apkg/){			
				if(greater($now_v,$ver)){
					print "$pkg-$now_v is installed. To install a lower version we have to remove it now.\n";
					system("sudo rpm -e $pkg --nodeps");
				}
			}
			system("sudo yum install -b stable -y $pkg-$ver");
                        system("sudo yum install -b current -y $pkg-$ver");
                }
                print "--check the $pkg version installed:---";
		system("rpm -qv $pkg | tee -a build_env.log");
            }
        }
    }
	
}

