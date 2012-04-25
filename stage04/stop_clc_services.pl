#!/usr/bin/perl
use strict;
use Cwd;

$ENV{'PWD'} = getcwd();

# does_It_Have( $arg1, $arg2 )
# does the string $arg1 have $arg2 in it ??
sub does_It_Have{
	my ($string, $target) = @_;
	if( $string =~ /$target/ ){
		return 1;
	};
	return 0;
};



#################### EUCALYPTUS COMPONENTS CHECK ##########################

my @ip_lst;
my @distro_lst;
my @version_lst;
my @arch_lst;
my @source_lst;
my @roll_lst;

my %cc_lst;
my %sc_lst;
my %nc_lst;

my $clc_index = -1;
my $cc_index = -1;
my $sc_index = -1;
my $ws_index = -1;

my $clc_ip = "";
my $cc_ip = "";
my $sc_ip = "";
my $ws_ip = "";

my $nc_ip = "";

my $rev_no = 0;

my $max_cc_num = 0;

my $index = 0;

my $vmbroker_group  = "";

$ENV{'EUCALYPTUS'} = "/opt/eucalyptus";

#### read the input list
read_input_file();


if( $source_lst[0] eq "PACKAGE" || $source_lst[0] eq "REPO" ){
	$ENV{'EUCALYPTUS'} = "";
};




###	STOP RUNNING CLC SERVICES
print "\n\n----------------------- Stopping All NON-NC Eucalyptus Cloud Components -----------------------\n";

my $is_error = 0;
my $is_applied = 0;

for( my $i = 0; $i <= @ip_lst && $is_error == 0; $i++){
	my $this_ip = $ip_lst[$i];
	my $this_distro = $distro_lst[$i];
	my $this_version = $version_lst[$i];
	my $this_arch = $arch_lst[$i];
	my $this_roll = $roll_lst[$i];

	$this_distro = lc($this_distro);

        ###     FOR 32-bit arch,
      #  if( $this_arch eq "32" ){
		###	if distro is CENTOS or RHEL 5,
		if( does_It_Have($this_distro, "centos") || ( does_It_Have($this_distro, "rhel") && $this_version =~ /^5\./ ) ){	

			stop_cloud_service($this_ip, $this_roll);
			print "\n";
			extra_check_on_cloud_service($this_ip, $this_roll);
			print "\n";
			$is_applied = 1;
		};
#	};
};

print "\n";

if( $is_error == 1 ){
	print "\n[TEST_REPORT]\tFAILED TO STOP CLC MACHINES !!!\n\n";
	exit(1);
};

if( $is_applied == 1 ){
	print "\n[TEST_REPORT]\tALL CLOUD SERVICES ARE STOPPED\n\n";
}else{
	print "\n[TEST_REPORT]\tNO ACTIONS TAKEN\n\n";
};

exit(0);





###################### SUBROUTINES  ########################################

sub print_time{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime(time);
        my $this_time = sprintf "[%4d-%02d-%02d %02d:%02d:%02d]\t", $year+1900,$mon+1,$mday,$hour,$min,$sec;
	return $this_time;
};


sub is_running {
    my $service = $_[0];
    my $this_ip = $_[1];

    print "\n\n----------------------- Checking Service $service on Machine $this_ip -----------------------\n";
    print "\n";
    
    print "ssh -o BatchMode=yes -o ServerAliveInterval=2 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$this_ip \"$service status\"\n";
    my $outstr = `ssh -o BatchMode=yes -o ServerAliveInterval=2 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$this_ip \"$service status\"`;
    print "\n";

    print $outstr;
    if( $outstr =~ /running/ ){
	print "$service at $this_ip is running !\n";
    }else{
	print "$service at $this_ip is not running!!\n";
	return 0;
    };
			
    return 1;
}


sub stop_cloud_service{

	my $outstr = "";
		
	my $this_ip = shift @_;
	my $this_roll = shift @_;;

	if( does_It_Have( $this_roll, "CC") ){
		print "\n\n----------------------- Stop CC $this_ip [ $this_roll ] -----------------------\n";
		print "\n$this_ip :: $ENV{'EUCALYPTUS'}/etc/init.d/eucalyptus-cc stop\n";

		#Stopping CC	### quick patch added for 2.0 upgrade
		print("ssh -o BatchMode=yes -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$this_ip \"$ENV{'EUCALYPTUS'}/etc/init.d/eucalyptus-cc stop\"\n");
		$outstr = `ssh -o BatchMode=yes -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$this_ip \"$ENV{'EUCALYPTUS'}/etc/init.d/eucalyptus-cc stop\"`;
		print "\n";

		print $outstr;
		print "\n";
		sleep(3);	
	};

	if( does_It_Have( $this_roll, "CLC") || does_It_Have( $this_roll, "SC") || does_It_Have( $this_roll, "WS") || does_It_Have( $this_roll, "VB")  ){

		print "\n\n----------------------- Stop Cloud $this_ip [ $this_roll ] -----------------------\n";

		print "\n$this_ip :: $ENV{'EUCALYPTUS'}/etc/init.d/eucalyptus-cloud stop\n";

		#Stopping CLOUD
		print("ssh -o BatchMode=yes -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$this_ip \"$ENV{'EUCALYPTUS'}/etc/init.d/eucalyptus-cloud stop\"\n");
		$outstr = `ssh -o BatchMode=yes -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$this_ip \"$ENV{'EUCALYPTUS'}/etc/init.d/eucalyptus-cloud stop\"`;
		print "\n";

		print $outstr;
		print "\n";

		if( $outstr =~ /done/ || $outstr =~ /no Eucalyptus services/ ){
			print "Stopped CLOUD Components $this_ip successfully !\n";
		}else{    
			if(is_running("$ENV{'EUCALYPTUS'}/etc/init.d/eucalyptus-cloud", $this_ip)) {
				print "\n[TEST_REPORT]\tFAILED to Stop CLOUD Components $this_ip !!\n";
				$is_error = 1;
			};
		};
		sleep(5);
	};

	return 0;
};


sub extra_check_on_cloud_service{

	my $outstr = "";
		
	my $this_ip = shift @_;
	my $this_roll = shift @_;

	if( does_It_Have( $this_roll, "CLC") || does_It_Have( $this_roll, "SC") || does_It_Have( $this_roll, "WS") || does_It_Have( $this_roll, "VB")  ){

		print "\n\n----------------------- Extra OP Cloud $this_ip [ $this_roll ] -----------------------\n";

		print "\n$this_ip :: cat $ENV{'EUCALYPTUS'}/etc/eucalyptus/eucalyptus-version\n";

		#Checking eucalyptus-version
		print("ssh -o BatchMode=yes -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$this_ip \"cat $ENV{'EUCALYPTUS'}/etc/eucalyptus/eucalyptus-version\"\n");
		$outstr = `ssh -o BatchMode=yes -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$this_ip \"cat $ENV{'EUCALYPTUS'}/etc/eucalyptus/eucalyptus-version\"`;
		print "\n";

		print $outstr;
		print "\n";

		if( $outstr =~ /eee-2/ ){
			sleep(5);
			print "It's eee 2.0. Needs to manually start tgtd\n";
			print("ssh -o BatchMode=yes -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$this_ip \"/etc/init.d/tgtd start\"\n");
			$outstr = `ssh -o BatchMode=yes -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$this_ip \"/etc/init.d/tgtd start\"`;
			print "\n";
			print $outstr;
			print "\n";
		};
		sleep(3);
	};

	return 0;
};





sub read_input_file{

	open( LIST, "../input/2b_tested.lst" ) or die "$!";
	my $line;
	while( $line = <LIST> ){
		chomp($line);
		if( $line =~ /^([\d\.]+)\t(.+)\t(.+)\t(\d+)\t(.+)\t\[(.+)\]/ ){
			print "IP $1 [Distro $2, Version $3, Arch $4] was built from $5 with Eucalyptus-$6\n";

			if( !( $2 eq "VMWARE" || $2 eq "WINDOWS" ) ){

				push( @ip_lst, $1 );
				push( @distro_lst, $2 );
				push( @version_lst, $3 );
				push( @arch_lst, $4 );
				push( @source_lst, $5 );
				push( @roll_lst, $6 );

				my $this_roll = $6;

				if( does_It_Have($this_roll, "CLC") ){
					$clc_index = $index;
					$clc_ip = $1;
				};

				if( does_It_Have($this_roll, "CC") ){
					$cc_index = $index;
					$cc_ip = $1;
	
					if( $this_roll =~ /CC(\d+)/ ){
						$cc_lst{"CC_$1"} = $cc_ip;
						if( $1 > $max_cc_num ){
							$max_cc_num = $1;
						};
					};			
				};

				if( does_It_Have($this_roll, "SC") ){
					$sc_index = $index;
					$sc_ip = $1;
	
					if( $this_roll =~ /SC(\d+)/ ){
	                	                $sc_lst{"SC_$1"} = $sc_ip;
	                	        };
				};

				if( does_It_Have($this_roll, "WS") ){
	                	        $ws_index = $index;
	                	        $ws_ip = $1;
	                	};
	
				if( does_It_Have($this_roll, "NC") ){
					$nc_ip = $1;
					if( $this_roll =~ /NC(\d+)/ ){
						if( $nc_lst{"NC_$1"} eq	 "" ){
	        	                        	$nc_lst{"NC_$1"} = $nc_ip;
						}else{
							$nc_lst{"NC_$1"} = $nc_lst{"NC_$1"} . " " . $nc_ip;
						};
	        	                };
	        	        };
				$index++;
	
			}elsif( $2 eq "VMWARE" ){
				my $this_roll = $6;
				if( does_It_Have($this_roll, "NC") ){
                                        if( $this_roll =~ /NC(\d+)/ ){
						if( !($vmbroker_group =~ /$1,/) ){
							$vmbroker_group .= $1 . ",";
						};
					};
				};
			};

	        }elsif( $line =~ /^BZR_REVISION\s+(\d+)/  ){
			$rev_no = $1;
			print "REVISION NUMBER is $rev_no\n";
		};
	};

	close( LIST );

	chop($vmbroker_group);

	return 0;
};
