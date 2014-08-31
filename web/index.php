<?php

$file = file_get_contents("/var/www/cooker.status");
$data = json_decode($file,true);
$state = $data["state"];

if($state == "WARMUP" || $state == "CONTROL" || $state == "COOLDOWN")
{
	header('Location: status.html');
}
else
{
	header('Location: start.php');
}

?>
