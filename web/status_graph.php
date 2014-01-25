<!DOCTYPE html>
<html>
<body>

<?php

$file = file_get_contents("/var/www/cooker.status");
$data = json_decode($file,true);
$start_time = $data["start_time"] + 30;

$graph_cmd = "rrdtool graph /var/www/cooker_status.png --start " . $start_time . " DEF:temp=" . $data["rrd_file"] . ":temp:AVERAGE LINE1:temp#0000FF HRULE:" . $data["setpoint"] . "#FF0000";

$output = shell_exec($graph_cmd);


$str .= "<br><img src=\"cooker_status.png\"><br>";


echo $str;


?>

</body>
</html>
