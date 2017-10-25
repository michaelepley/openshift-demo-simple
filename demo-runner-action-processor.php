<html>
 <head>
  <title>Openshift PHP+MySQL demo runner action processor</title>
  <style>
	table, th, td {
	  border: 1px solid black;
	  border-collapse: collapse;
	} 
	th, td {
	  padding: 5px;
	  text-align: left;
	}
  </style>
</head>
<body>
<?php

error_reporting(E_ERROR);

if (isset($_GET['results'])) {
	header("Refresh: 2; URL=$url");
	$results = $_GET['results'];
	switch ($results) {
		case 'setup_php':
			show_php();
			break;
		case 'setup_db':
			show_db();
			break;
		case 'setup_connect':
			show_connect();
			break;
		case 'setup_scale':
			show_scale();
			break;
		case 'setup_versions':
			show_versions();
			break;
		case 'setup_builds':
			show_builds();
			break;
		default:
			echo "unknown results requesteds";
	}
}

if (isset($_GET['action'])) {
	$action = $_GET['action'];
	# echo '<pre>' . print_r($_ENV, true) . '</pre>';
	switch ($action) {
		case 'setup_php':
			setup_php();
			break;
		case 'setup_db':
			setup_db();
			break;
		case 'setup_connect':
			setup_connect();
			break;
		case 'setup_scale':
			setup_scale();
			break;
		case 'setup_versions':
			setup_versions();
			break;
		case 'setup_builds':
			setup_builds();
			break;
		case 'clean':
			clean();
			break;
		default:
			echo "unknown action triggered";
	}
}

function setup_php() {
	echo "The setup_php function is called.";
	if (isset($_GET["basedir"])) {
		$basedir=$_GET["basedir"];
		if($basedir != "") chdir('/basedir');
	}
	$output = shell_exec('./setup-php.sh > setup-php-output.txt &');
	exit;
}

function show_php() {
	$fileLocation = "setup-php-output.txt";
  $file = fopen($fileLocation,"w");
  fwrite($file,$output);
  fclose($file);
  echo '<pre>';
  echo $output;
  echo '</pre>';
	exit;
}

function setup_db() {
	echo "The setup_db function is called.";
	if (isset($_GET["basedir"])) {
		$basedir=$_GET["basedir"];
		if($basedir != "") chdir('/basedir');
	}
	$output = shell_exec('./setup-db.sh  > setup-db-output.txt &');
	exit;
}

function show_db() {
	$fileLocation = getenv("DOCUMENT_ROOT") . "/setup-db-output.txt";
  $file = fopen($fileLocation,"w");
  fwrite($file,$output);
  fclose($file);
  echo '<pre>';
  echo $output;
  echo '</pre>';
	exit;
}

function setup_connect() {
	echo "The setup_connect function is called.";
	if (isset($_GET["basedir"])) {
		$basedir=$_GET["basedir"];
		if($basedir != "") chdir('/basedir');
	}
	$output = shell_exec('./setup-connect.sh  > setup-connect-output.txt &');
	exit;
}

function show_connect() {
  $output = shell_exec("cat setup-connect-output.txt");
  echo "Results:";
  echo '<pre>';
  echo $output;
  echo '</pre>';
	exit;
}

function setup_scale() {
	echo "The setup_scale function is called.";
	if (isset($_GET["basedir"])) {
		$basedir=$_GET["basedir"];
		if($basedir != "") chdir('/basedir');
	}
	shell_exec('./setup-scale.sh > setup-scale-output.txt &');
	exit;
}

function show_scale() {
  $output = shell_exec("cat setup-scale-output.txt");
  echo "Results:";
  echo '<pre>';
  echo $output;
  echo '</pre>';
	exit;
}

function setup_versions() {
	echo "The setup_versions function is called.";
	if (isset($_GET["basedir"])) {
		$basedir=$_GET["basedir"];
		if($basedir != "") chdir('/basedir');
	}
	$output = shell_exec('./setup-versions.sh > setup-versions-output.txt &');
	exit;
}

function show_versions() {
  $output = shell_exec("cat setup-versions-output.txt");
  echo "Results:";
  echo '<pre>';
  echo $output;
  echo '</pre>';
	exit;
}

function setup_builds() {
	echo "The setup_builds function is called.";
	if (isset($_GET["basedir"])) {
		$basedir=$_GET["basedir"];
		if($basedir != "") chdir('/basedir');
	}
	$output = shell_exec('./setup-builds.sh  > setup-builds-output.txt &');
	exit;
}

function show_builds() {
  $output = shell_exec("cat setup-builds-output.txt");
  echo "Results:";
  echo '<pre>';
  echo $output;
  echo '</pre>';
	exit;
}

function clean() {
	echo "The cleab function is called.";
	if (isset($_GET["basedir"])) {
		$basedir=$_GET["basedir"];
		if($basedir != "") chdir('/basedir');
	}
	$output = shell_exec('./clean.sh  > clean-output.txt &');
	exit;
}


?>
</div>
 </body>
</html>
