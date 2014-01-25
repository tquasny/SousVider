<?php

if($_REQUEST["usrTemp"] != "")
{
	$setpoint = $_REQUEST["usrTemp"];
}
else
{
	$setpoint = $_REQUEST["preTemp"];
}


$title = "Configured from the Web";
$p = 8;
$i = 2;
$ramp = 3;
$rrd = "/home/pi/cooker/cooker.rrd";

$str = "Title=\"" . $title . "\"\n";
$str .= "SetpointF=" . $setpoint . "\n";
$str .= "p=" . $p . "\ni=" . $i . "\nRampToWithin=" . $ramp . "\n";
$str .= "RRD=" . $rrd . "\nEnabled=True\n";

file_put_contents("/var/www/cooker.config",$str);
shell_exec('sudo /usr/bin/nohup /home/pi/cooker/cooker.pl /var/www/cooker.config >/dev/null 2>&1 &');

header("Location: status.html");

?>
