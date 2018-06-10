<?
// COMP3311 18s1 Assignment 2
// Global configuration file
// This file must be included at the start of all scripts

// Global configuration constants

define("BASE_DIR","/import/adams/2/z5113243/cs3311-ass2");
define("LIB_DIR",BASE_DIR."/lib");
define("DB_CONNECTION","dbname=a2");

// Important libraries which are always included

require_once(LIB_DIR."/db.php");
require_once(LIB_DIR."/rules.php");
require_once(LIB_DIR."/a2.php");

# libs: include a bunch of libraries
# - library names supplied as arguments
# - names containing / or .php are assumed to be local libraries
# - all other names are assumed to be libraries from SYS/lib

function libs()
{
	$libs = func_get_args();
	foreach ($libs as $lib)
	{
		if (strstr($lib,'/') || (strstr($lib,'.php')))
			$libFile = $lib;
		else
			$libFile = LIB_DIR."/$lib.php";
		require_once("$libFile");
	}
}

?>
