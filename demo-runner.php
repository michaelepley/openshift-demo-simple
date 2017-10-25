<html>
 <head>
  <title>Openshift PHP+MySQL demo</title>
  <style>
    .hide { position:absolute; top:-1px; left:-1px; width:1px; height:1px; }
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    } 
    th, td {
      padding: 5px;
      text-align: left;
    }
  </style>
	<script>
		function setTarget(theTarget)      { var element=document.getElementById("script_form"); element.setAttribute("action", "demo-runner-action-processor.php?action=" + theTarget); element.setAttribute("target", theTarget+"_results"); }
		function setup_php()      { document.getElementById("setup_php").innerHTML="The setup_php function is called"; }
		function setup_db()       { document.getElementById("setup_db").innerHTML="The setup_db function is called."; }
		function setup_connect()  { document.getElementById("setup_connect").innerHTML="The setup_connect function is called."; }
		function setup_scale()    { document.getElementById("setup_scale").innerHTML="The setup_scale function is called."; }
		function setup_versions() { document.getElementById("setup_versions").innerHTML="The setup_versions function is called."; }
		function setup_builds()   { document.getElementById("setup_builds").innerHTML="The setup_builds function is called."; }
		function clean()          { document.getElementById("clean").innerHTML="The clean function is called."; }
	</script>
</head>
<body>
<!-- See https://github.com/blog/273-github-ribbons -->
<!-- See https://stackoverflow.com/questions/20738329/how-to-call-a-php-function-on-the-click-of-a-button -->
<a href="https://github.com/michaelepley/openshift-demo-simple"><img style="position: absolute; top: 0; left: 0; border: 0;" src="https://camo.githubusercontent.com/121cd7cbdc3e4855075ea8b558508b91ac463ac2/68747470733a2f2f73332e616d617a6f6e6177732e636f6d2f6769746875622f726962626f6e732f666f726b6d655f6c6566745f677265656e5f3030373230302e706e67" alt="Fork me on GitHub" data-canonical-src="https://s3.amazonaws.com/github/ribbons/forkme_left_green_007200.png"></a>
<div align="center" width="80%">
<h1>Openshift PHP+MySQL demo</h1>
<p id="current_stage"></p>
<form id="script_form_setup_php" action="demo-runner-action-processor.php?action=setup_php" method="post" target="_blank">
	<input type="submit" class="button" name="setup_php" value="Setup PHP App" onclick="setup_php()"/>
	<p id="setup_php"></p>
	<iframe name="setup_php_results" width="80%" height="50"></iframe>
	<br/>
</form>
<form id="script_form_setup_db" action="demo-runner-action-processor.php?action=setup_db" method="post" target="_blank">
	<input type="submit" class="button" name="setup_db" value="Setup DB" onclick="setup_db()"/>
	<p id="setup_db"></p>
	<iframe name="setup_versions_results" width="80%" height="50"></iframe>
	<br/>
</form>
<form id="script_form_setup_connect" action="demo-runner-action-processor.php?action=setup_connect" method="post" target="_blank">
	<input type="submit" class="button" name="setup_connect" value="Connect PHP App to DB" onclick="setup_connect()"/>
	<p id="setup_connect"></p>
	<iframe name="setup_versions_results" width="80%" height="50"></iframe>
	<br/>
</form>
<form id="script_form_setup_scale" action="demo-runner-action-processor.php?action=setup_scale" method="post" target="_blank">
	<input type="submit" class="button" name="setup_db" value="Setup Scale" onclick="setup_scale()"/>
	<p id="setup_scale"></p>
	<iframe name="setup_versions_results" width="80%" height="50"></iframe>
	<br/>
</form>
<form id="script_form_setup_versions" action="demo-runner-action-processor.php?action=setup_versions" method="post" target="_blank">
	<input type="submit" class="button" name="setup_versions" value="Setup Versions" onclick="setup_versions()"/>
	<p id="setup_versions"></p>
	<iframe name="setup_versions_results" width="80%" height="50"></iframe>
	<br/>
</form>
<form id="script_form_setup_builds" action="demo-runner-action-processor.php?action=setup_builds" method="post" target="_blank">
	<input type="submit" class="button" name="setup_db" value="Setup Builds" onclick="setup_builds()"/>
	<p id="setup_builds"></p>
	<iframe name="setup_builds_results" width="80%" height="50"></iframe>
	<br/>
</form>
<form id="script_form_clean" action="demo-runner-action-processor.php?action=clean" method="post" target="_blank">
	<input type="submit" class="button" name="clean" value="CLEAN UP" onclick="clean()"/>
	<p id="setup_builds"></p>
	<iframe name="setup_builds_results" width="80%" height="50"></iframe>
	<br/>
</form>
<p>Results:</p>
<br/>
<iframe name="general_results"/>

<?php
// <!-- Automatically refresh page every few seconds, if the refresh request parameter is provided -->  
if (isset($_GET["refresh"])) {
	$refresh=$_GET["refresh"]; 
	$url=$_SERVER['REQUEST_URI'];
	header("Refresh: $refresh; URL=$url");
}
 
error_reporting(E_ERROR);

?>
</div>
 </body>
</html>
