<!DOCTYPE html>
<html>
<head>
<title>Sous Vides - Start Here</title>
<meta name="viewport" content="width=device-width, height=device-height">
</head>

<body>

<h1>Sous Vider</h1>
<form action="cooker.php" method="post">
  <select name="preTemp">
    <option value=140>Chicken Breast (140)</option>
    <option value=110>Fish (110)</option>
    <option value=122>Steak - Blue (122)</option>
    <option value=130>Steak - Rare (130)</option>
    <option value=132>Steak - Medium Rare(132)</option>
    <option value=135>Steak - Medium (135)</option>
    <option value=137>Steak - Medium Well (137)</option>
    <option value=140>Steak - Well (140)</option>
    <option value=132.8>Hamburgers (132.8)</option>
    <option value=132>Lamb Loin or Chops (132)</option>
    <option value=147.5>Turkey Breast (147.5)</option>
    <option value=185>Vegetables (185)</option>

    <?php

       for($i=100;$i<221;$i++)
          echo "<option value=" . $i . ">Temp: " . $i . "</option>\n";

    ?>

  </select>

<br><br>
<input type="submit" value="Start Cooking"></input>

<br><br>


</form>
</body>

</html>
