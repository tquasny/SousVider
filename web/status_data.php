<!DOCTYPE html>
<html>
<body>

<?php

$file = file_get_contents("/var/www/cooker.status");
$data = json_decode($file,true);
$state = $data["state"];


$str = "<h1>" . $data["title"] . "</h1>";
$str .= "The temperature is " . $data["temp"] . " &deg;F<br>";
$str .= "The setpoint is " . $data["setpoint"] . " &deg;F<br>";
$str .= "The cooker state is " . $data["state"] . "<br>";
$str .= "The heater is currently " . $data["power"] . "<br>";
$str .= "Current error is " . $data["error"] . "&deg;F<br>";

if($state == "WARMUP" || $state == "CONTROL" || $state == "COOLDOWN")
{
   $str .= "<form action=\"disable.php\"><input type=\"submit\" value=\"Turn Off\"></form><br>";
}
else
{
   $str .= "<form action=\"index.php\"><input type=\"submit\" value=\"Return to Home Page\"></form><br>";
}


echo $str;


?>

</body>
</html>
