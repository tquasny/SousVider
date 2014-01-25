<?php

$file = file_get_contents("/var/www/cooker.status");
$data = json_decode($file,true);

$title = $data["title"];
$p = 8;
$i = 2;
$ramp = 3;
$rrd = "/home/pi/cooker/cooker.rrd";
$setpoint = $data["setpoint"];

$str = "Title=\"" . $title . "\"\n";
$str .= "SetpointF=" . $setpoint . "\n";
$str .= "p=" . $p . "\ni=" . $i . "\nRampToWithin=" . $ramp . "\n";
$str .= "RRD=" . $rrd . "\nEnabled=False\n";

file_put_contents("/var/www/cooker.config",$str);

header("Location: status.html");

?>
