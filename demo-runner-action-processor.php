<html>
 <head>
  <title>Demo runner action processor</title>
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
<div align="center" width="80%">
<h1>Openshift PHP+MySQL demo runner action processor</h1>

<?php

error_reporting(E_ERROR);

if (isset($_POST['action'])) {
	switch ($_POST['action']) {
		case 'setup-php':
			setup-php();
			break;
		case 'setup-db':
			setup-db();
			break;
		case 'setup-connect':
			setup-db();
			break;
		case 'setup-scale':
			setup-db();
			break;
		case 'setup-versions':
			setup-db();
			break;
		case 'setup-builds':
			setup-db();
			break;
	}
}

function setup-php() {
	echo "The setup-php function is called.";
	if (isset($_GET["basedir"])) {
		$basedir=$_GET["basedir"];
		if($basedir != "") chdir('/basedir');
	}
	$output = shell_exec('./setup-php.sh');
	$fileLocation = getenv("DOCUMENT_ROOT") . "/setup-php-output.txt";
  $file = fopen($fileLocation,"w");
  fwrite($file,$output);
  fclose($file);
	exit;
}

function setup-db() {
	echo "The setup-db function is called.";
	exit;
}

function setup-connect() {
	echo "The setup-connect function is called.";
	exit;
}

function setup-scale() {
	echo "The setup-scale function is called.";
	exit;
}

function setup-versions() {
	echo "The setup-versions function is called.";
	exit;
}

function setup-builds() {
	echo "The setup-builds function is called.";
	exit;
}


?>
</div>
 </body>
</html>
