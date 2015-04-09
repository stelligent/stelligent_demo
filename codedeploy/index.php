<?php
	ini_set('display_errors',1);
	ini_set('display_startup_errors',1);
	error_reporting(-1);
	date_default_timezone_set('America/New_York');
	$dbName = file_get_contents('/etc/cfn/NandoDemoDBName');
	$dbUser = file_get_contents('/etc/cfn/NandoDemoDBUser');
	$dbPass = file_get_contents('/etc/cfn/NandoDemoDBPass');
	$dbHost = file_get_contents('/etc/cfn/NandoDemoDBHost');
	$conn = new mysqli($dbHost, $dbUser, $dbPass, $dbName);
	if ($conn->connect_error) { die("Connection failed: " . $conn->connect_error); } 
	$placeImage1 = rand(1,20);
	$placeImage2 = rand(1,20);
	if ($placeImage1 == $placeImage2) { $placeImage2++; }
	echo "<html><body>" . date(DATE_RFC2822) . "<br>Connected to " . $dbHost . "<table border=0 width=100%><tr>";
	for ($placeHolder = 0; $placeHolder < 20; $placeHolder++) { 
		if ($placeHolder % 5 == 0) { echo "</tr><tr>"; }
		if ($placeHolder == $placeImage1) { echo "<td width=20% align=center><img src=image1.jpg></td>"; }
    		elseif ($placeHolder == $placeImage2) { echo "<td width=20% align=center><img src=image2.jpg></td>"; }
		else { 
			echo "<td width=20% align=center>"; 
    			for ($tddata = 0; $tddata < 8; $tddata++) {
        			echo rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . " " . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . "<br>"; 
			}
       			echo rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . " " . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . "</td>"; 
		}
	}
	echo "</tr></table>";
	phpinfo();
	echo "</body></html>"
?>
