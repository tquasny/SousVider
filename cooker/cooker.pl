#!/usr/bin/perl

use strict;
use warnings;
use Device::BCM2835;
use POSIX;

sub read_config;
sub get_temperature;
sub pwr_on;
sub pwr_off;
sub catch_reset;
sub create_rrd;
sub check_config;
sub catch_sigint;
sub write_status;
sub set_rate;

my %CONFIG;
my $status_filename = "/var/www/cooker.status";

my $rrd_file;
my $target;
my $prop;
my $integral;
my $warm_up_to_within;
my $config_time;
my $configfilename = "";
my $title;

if(@ARGV != 1)
{
    die "Usage: cooker.pl <config file>\n";
}
else
{
    $configfilename = $ARGV[0];
}

read_config();

#Initialize GPIO
Device::BCM2835::init() || die "Could not init BCM2835 device";
Device::BCM2835::gpio_fsel(&Device::BCM2835::RPI_GPIO_P1_11, 
                            &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);    


#Install interrupt handlers
$SIG{'HUP'} = \&catch_sigint;
$SIG{'INT'} = \&catch_sigint;
$SIG{'KILL'} = \&catch_sigint;

my $interror = 0;
my $error = 0;
my $power;
my $out;
my $pwr_state;
my $cooker_state = "WARMUP";
my $cooker_start_time = time;
my $x;
my $previous_temp = 0;
my $previous_time = 0;
my $rate = 0;
my $rate_number = 0;

create_rrd();

while($CONFIG{'Enabled'} ne "True")
{
    check_config();
}

my $state = "on";
pwr_on();

my $t = get_temperature();


while(1)
{

    #See if the config file has changed
    check_config();

    $t = get_temperature();

    if(($target - $t) > $warm_up_to_within)
    {
	$cooker_state = "WARMUP";
    }
    elsif(($t - $target) > $warm_up_to_within)
    {
	$cooker_state = "COOLDOWN";
    }
    else
    {
	$cooker_state = "CONTROL";
    }

    if($cooker_state eq "WARMUP")
    {
	if($pwr_state ne "ON")
	{
	    pwr_on();
	}

	for($x=0; $x<15; $x++)
	{
	    check_config();
	    sleep(1);
	}

	$t = get_temperature();
	$interror = 0;
    }

    if($cooker_state eq "COOLDOWN")
    {
	if($pwr_state ne "OFF")
	{
	    pwr_off();
	}

	sleep(15);
	$t = get_temperature();
	$interror = 0;
    }

    if($cooker_state eq "CONTROL")
    {

	$error = $target - $t;
	$interror = $interror + $error;
	$power = (($prop * $error) + (($integral * $interror)/100))/100;
    
	for ($x=0; $x<100; $x++)
	{
	    if($power > $x)
	    {
		if($state eq "off")
		{
		    $state = "on";
		    pwr_on();
		}
	    }
	    else
	    {
		if($state eq "on")
		{
		    $state = "off";
		    pwr_off();
		}
	    }
	    
	    if(($x % 10) == 0)
	    {
		get_temperature(); #force an update to the DB
	    }

	    check_config();
	    sleep(1);
	    
	    
	}#pwm loop
	
    }#control

}#while 1


sub get_temperature
{

    my $modules;
    my $gpio;
    my $therm;
    my $output;
    my $attempts;
    my $temp_raw;
    my $temp;
    my $tempF;
    my $retval;
    
    
    $modules = `cat /proc/modules`;
    if ($modules =~ /w1_therm/ && $modules =~ /w1_gpio/)
    {
	#modules installed
    }
    else
    {
	$gpio = `sudo modprobe w1-gpio`;
	$therm = `sudo modprobe w1-therm`;
    }
    
    $output = "";
    $attempts = 0;
    while ($output !~ /YES/g && $attempts < 5)
    {
	$output = `sudo cat /sys/bus/w1/devices/28-*/w1_slave 2>&1`;
        if($output =~ /No such file or directory/)
        {
	    print "Could not find DS18B20\n";
	    last;
        }
        elsif($output !~ /NO/g)
        {
	    $output =~ /t=(\d+)/i;
	    $temp_raw = ($1) * 9/5 + 32;              
	    $tempF = ($1 / 1000) * 9/5 + 32;
	    $temp = $1; #added to line up with example code
	}
	
	$attempts++;
    }

    $output = `rrdtool update $rrd_file N:$tempF`;
    set_rate($tempF);
    write_status($tempF);

    #return the milli-celsius temp
    $retval = $temp;


}#end get_temperature

sub pwr_on()
{

    Device::BCM2835::gpio_write(&Device::BCM2835::RPI_GPIO_P1_11, 1);
    Device::BCM2835::delay(500); # Milliseconds

    $pwr_state = "ON";

}#end pwr_on

sub pwr_off()
{
    Device::BCM2835::gpio_write(&Device::BCM2835::RPI_GPIO_P1_11, 0);
    Device::BCM2835::delay(500); # Milliseconds
    
    $pwr_state = "OFF";

}#end pwr_off


sub read_config()
{

    open(INF,"$configfilename");
    while (<INF>) {
	chomp;                  # no newline
	s/#.*//;                # no comments
	s/^\s+//;               # no leading white
	s/\s+$//;               # no trailing white
	next unless length;     # anything left?
	my ($var, $value) = split(/\s*=\s*/, $_, 2);
	$CONFIG{$var} = $value;
    } 
    close(INF);

    $rrd_file = $CONFIG{'RRD'};
    $target = $CONFIG{'SetpointF'};
    $prop = $CONFIG{'p'};
    $integral = $CONFIG{'i'};
    $warm_up_to_within = $CONFIG{'RampToWithin'};
    (undef,$title,undef) = split("\"",$CONFIG{'Title'});

    #Convert target to celsius then multiply by 1000
    $target = ($target - 32.0) * (5.0 / 9.0);
    $target *= 1000;

    $warm_up_to_within *= 1000;

    $config_time = -M $configfilename;

}

sub create_rrd
{
    #Create the RRD
    if(-f $rrd_file)
    {
	#Do nothing since RRD already exists
    }
    else
    {
	system("rrdtool create $rrd_file --start N --step 1 DS:temp:GAUGE:240:U:U RRA:AVERAGE:0.5:1:14400");
    }
}


sub check_config
{
    my $current_config_time = -M $configfilename;

    if($current_config_time != $config_time)
    {
	read_config();
	$interror = 0;
    }

    #Make sure we are still enabled.  If not, die
    if($CONFIG{'Enabled'} ne "True")
    {
	pwr_off();
	$cooker_state = "DONE";
	get_temperature();
	exit(0);
    }


}

sub catch_sigint
{
    print "Exiting...\n";
    pwr_off();
    $cooker_state = "KILLED";
    get_temperature();
    exit(0);
}

sub write_status
{

    my $tmp = $_[0];
    my $sp = $target / 1000.0;
    my $str = "";
    my $error;
    my $time_to_target;

    if($tmp ne "N/A")
    {
	$tmp = sprintf("%.2f",$tmp);
    }
    $sp = ($sp * 9.0 / 5.0) + 32.0;

    $error = $sp - $tmp;

    $error = sprintf("%.2f",$error);

    #Calculate the number of seconds to reach target
    if($rate == 0)
    {
	$time_to_target = 999999;
    }
    else
    {
	$time_to_target = $error / $rate;
    }

    #Convert to number of minutes and format
    $time_to_target = sprintf("%.6f",$time_to_target / 60.0);

    $rate = sprintf("%.4f",$rate);

    $str .= "{ \"title\" : \"$title\" , \"temp\" : $tmp , \"setpoint\" : $sp , ";
    $str .= "\"state\" : \"$cooker_state\" , \"power\" : \"$pwr_state\" , \"error\" : $error , ";
    $str .= "\"start_time\" : $cooker_start_time , \"rrd_file\" : \"$rrd_file\" , ";
    $str .= "\"rate\" : $rate , \"time_to_target\" : $time_to_target }";

    open(OUTF, ">$status_filename");
    print OUTF "$str\n";
    close(OUTF);

}

sub set_rate
{
    my $current_temp = $_[0];
    my $current_time = time;
    my $temp_delta = $current_temp - $previous_temp;
    my $time_delta = $current_time - $previous_time;

    #Get the rate in degrees per second
    if($time_delta != 0 && $rate_number == 10)
    {
	$rate = $temp_delta / $time_delta;
	$rate_number = 0;
    }
    else
    {
	$rate_number++;
    }

    $previous_temp = $current_temp;
    $previous_time = $current_time;

}
