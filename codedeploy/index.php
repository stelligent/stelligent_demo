<?php
	ini_set('display_errors',1);
	ini_set('display_startup_errors',1);
	error_reporting(-1);
	date_default_timezone_set('America/New_York');
	$dbName = trim(file_get_contents('/etc/cfn/NandoDemoDBName'));
	$dbUser = trim(file_get_contents('/etc/cfn/NandoDemoDBUser'));
	$dbPass = trim(file_get_contents('/etc/cfn/NandoDemoDBPass'));
	$dbHost = trim(file_get_contents('/etc/cfn/NandoDemoDBHost'));
	$placeImage1 = rand(1,8);
	$placeImage2 = rand(1,8);
	if ($placeImage1 == $placeImage2) { $placeImage2++; }
	echo "<html><body bgcolor=green>";
        echo date(DATE_RFC2822);
        echo "<p>Database: <b>" . $dbHost . "</b><br>";
	$conn = new mysqli($dbHost, $dbUser, $dbPass, $dbName);
	if ($conn->connect_error) { die("Connection failed: " . $conn->connect_error); } 
        if (! $result = $conn->query("show databases")) { printf("Error: %s\n", $mysqli->error); }
	while ($row = mysqli_fetch_row($result)) { echo $row[0] . " : "; }
  	mysqli_free_result($result);
	mysqli_close($conn);
        echo "<p>Application running on <b>";
        echo exec('curl http://169.254.169.254/latest/meta-data/public-hostname');
        echo "</b><p>AMI: <b>";
        echo exec('curl http://169.254.169.254/latest/meta-data/ami-id');
        echo "<br></b> Hostname: <b>";
        echo exec('curl http://169.254.169.254/latest/meta-data/hostname');
        echo "<br></b> InstanceID: <b>";
        echo exec('curl http://169.254.169.254/latest/meta-data/instance-id');
        echo "<br></b> InstanceType: <b>";
        echo exec('curl http://169.254.169.254/latest/meta-data/instance-type');
        echo "<br></b> KernelID: <b>";
        echo exec('curl http://169.254.169.254/latest/meta-data/kernel-id');
        echo "<br></b> Localhost: <b>";
        echo exec('curl http://169.254.169.254/latest/meta-data/local-hostname');
        echo "<br></b> PrivateIP: <b>";
        echo exec('curl http://169.254.169.254/latest/meta-data/local-ipv4');
        echo "<br></b> MacAddr: <b>";
        echo exec('curl http://169.254.169.254/latest/meta-data/mac');
        echo "<br></b> PublicIP: <b>";
        echo exec('curl http://169.254.169.254/latest/meta-data/public-ipv4');
        echo "<br></b> SecurityGroup: <b>";
        echo exec('curl http://169.254.169.254/latest/meta-data/security-groups');
 	echo "<br><p><table border=0 width=100%><tr>";
	for ($placeHolder = 0; $placeHolder < 8; $placeHolder++) { 
		if ($placeHolder % 4 == 0) { echo "</tr><tr>"; }
		if ($placeHolder == $placeImage1) { echo "<td width=20% align=center><img src=http://nando-automation-demo.s3.amazonaws.com/public/AWS-logo.jpg width=100></td>"; }
    		elseif ($placeHolder == $placeImage2) { echo "<td width=20% align=center><img src=http://nando-automation-demo.s3.amazonaws.com/public/AWS-logo.jpg width=100></td>"; }
		else { 
			echo "<td width=20% align=center>"; 
    			for ($tddata = 0; $tddata < 8; $tddata++) {
        			echo rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . " " . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . "<br>"; 
			}
       			echo rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . " " . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . "</td>"; 
		}
	}
	echo "</tr></table><p>";
        echo "<img src=http://nando-automation-demo.s3.amazonaws.com/public/stelligent.gif width=65% align=right>";
	echo "</body></html>";
?>
