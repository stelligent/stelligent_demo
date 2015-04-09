<?php

	echo "<html><body>" . date(DATE_RFC2822) . "<br><table border=0 width=100%><tr>";

	$placeImage1 = rand(0,19);
	$placeImage2 = rand(0,19);

	for ($placeHolder = 0; $placeHolder < 20; $placeHolder++) { 
		if ($placeHolder % 5 == 0) { echo "</tr><tr>"; }
		if ($placeHolder == $placeImage1) { echo "<td width=20% align=center><img src=image1.jpg></td>"; }
    		elseif ($placeHolder == $placeImage2) { echo "<td width=20% align=center><img src=image2.jpg></td>"; }
		else { echo "<td width=20% align=center>"; }
    		for ($tddata = 0; $tddata < 9; $tddata++) {
			echo $tddata;
        		echo rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . " " . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . "<br>"; 
		}
       		echo rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . " " . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . rand(0,1) . "</td>"; 
	}
	echo "</tr></table></body></html>"
?>
