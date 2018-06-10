<?php
// COMP3311 13s2 Assignment 3
// Print a transcript for a student up to a given term
// Written by John Shepherd, 2011..2013

require("lib/defs.php"); libs("db","rules");
$usage = "Usage: $argv[0] StudentID Term";
$db = dbConnect(DB_CONNECTION);

// Check arguments

if (count($argv) < 3) exit("$usage\n");
list($x,$stuid,$term) = $argv;

// Get/check student
$q = "select id,name from People where unswid = %d";
$t = dbOneTuple($db, mkSQL($q, $stuid));
if (empty($t)) exit("Invalid student ($stuid)\n");
list($sid,$name) = $t;

// Get/check term
$q = "select id from Semesters where termName(id) = %s";
$tid = dbOneValue($db, mkSQL($q, $term));
if (empty($tid)) exit ("Invalid term ($term)\n");

// Display enrolment info

echo "$name ($stuid)\n";

// Programs/steam enrolments

echo "\nProgram/Stream enrolments:\n";
echo   "--------------------------\n";
$progFmt = "%4s  %4s  %s\n";
$enrs = collectProgStrmEnrolments($db, $sid, $tid);
if (count($enrs) < 1)
	echo "No program/stream enrolment data\n";
else {
	printf($progFmt, "Term","Prog","Stream");
	foreach ($enrs as $e) {
		printf($progFmt, $e[0],$e[1],$e[2]);
	}
}

// Course enrolments
echo "\nCourse enrolments (transcript):\n";
echo   "-------------------------------\n";
$courseFmt = "%8s %4s %-30.30s %5s %5s %5s\n";
$enrs = collectCourseEnrolments($db, $sid, $tid);
if (count($enrs) < 2)
	echo "No course enrolment data\n";
else {
	printf($courseFmt, "Course","Term","Title","Mark","Grade","UOC");
	foreach ($enrs as $e) {
		printf($courseFmt, $e[0],$e[1],$e[2],$e[3],$e[4],$e[5]);
	}
}

exit(0);

// Helpers

function getProgStrmEnrolments()
{
return <<<_SQL_
select termName(pe.semester), p.code as program,
         coalesce(s.code,'Unknown') as stream
from   Program_enrolments pe
         join Semesters t on (pe.semester = t.id)
         join Programs p on (pe.program = p.id)
         left outer join Stream_enrolments se on (se.partof = pe.id)
         left outer join Streams s on (se.stream = s.id)
where  pe.student = %d and pe.semester <= %d
order  by t.starting
_SQL_;
}

function collectProgStrmEnrolments($db, $sid, $tid)
{
	$r = dbQuery($db, mkSQL(getProgStrmEnrolments(), $sid, $tid));
	$results = array();
	while ($t = dbNext($r)) {
		list($term, $prog, $strm) = $t;
		$results[] = array($term,$prog,$strm);
	}
	return $results;
}

function collectCourseEnrolments($db, $sid, $tid)
{
	// luckily we already have a suitable transcript() function
	$q = "select * from transcript(%d,%d)";
	$r = dbQuery($db, mkSQL($q, $sid, $tid));
	$results = array();
	while ($t = dbNext($r)) {
		list($code,$term,$title,$mark,$grade,$uoc) = $t;
		$mark = is_null($mark) ? "" : sprintf("%d",$mark);
		if (!empty($grade) && !isPass($grade)) $uoc = "";
		$uoc = is_null($uoc) ? "" : sprintf("%d",$uoc);
		$results[] = array($code,$term,$title,$mark,$grade,$uoc);
	}
	return $results;
}

function isPass($grade)
{
	$passGrades = array("PC"=>1,"PS"=>1,"CR"=>1,"DN"=>1,"HD"=>1,"SY"=>1);
	return(isset($passGrades[$grade]));
}
?>
