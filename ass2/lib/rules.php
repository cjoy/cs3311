<?
// COMP3311 18s1 Assignment 2
// Functions related to Rules

// assumes that defs.php has already been included

# showRule:
# - return rule in human-readable form

function showRule($db,$rid)
{
	$q = "select * from Rules where id = %d";
	$rule = dbOneTuple($db, mkSQL($q,$rid));
	list($id,$name,$reqtype,$min,$max,$gid) = $rule;
	$text = "[$id] ";
	switch ($reqtype) {
	case "CC":
	case "PE":
	case "RQ":
		$text .= showGroup($db,$rule);
		break;
	case "DS":
		$text .= "completed requirements of ".showGroup($db,$rule);
		break;
	case "MR":
		$text .= "maturity: ";
		if (empty($min) && empty($max))
			$text .= "?($id,$name,$reqtype,$min,$max,$gid)";
		else
			$text .= showGroup($db,$rule);
		break;
	case "LR":
		$text .= "level: ";
		if (empty($min) && empty($max))
			$text .= "?($id,$name,$reqtype,$min,$max,$gid)";
		else
			$text .= showGroup($db,$rule);
		break;
	case "WM":
		$text .= "WAM $min or better";
		break;
	case "FE":
		$text .= uoc($min,$max);
		$text .= " of Free Electives";
		break;
	case "GE":
		$text .= uoc($min,$max);
		$text .= " of General Education courses";
		break;
	case "RC":
		$text .= "recommended: ";
		$text .= empty($gid) ? $name : showGroup($db,$rule);
		break;
	case "IR":
		$text .= "information: $name";
		break;
	default:
		$text .= "?Rule($id,$name,$reqtype,$min,$max,$gid)";
		break;
	}
	# DBUG
	# $text .= sprintf("\n%12s  %s"," ","Rule($id,$name,$reqtype,$min,$max,$gid)");
	return $text;
}

function uoc($min,$max,$g=0)
{
	if (empty($min) && empty($max))
		return "some UOC";
	elseif (empty($min) || $min == 0)
		return "at most {$max} UOC";
	elseif (empty($max) || $max == 999)
		return "at least {$min} UOC";
	elseif ($min <= 6 && $min == $max) { // hacky!
		return "one of";
	}
	elseif ($min == $max)
		return "{$min} UOC";
	else
		return "between {$min} UOC and {$max} UOC";
}

function showGroup($db,$rule)
{
	$res = membersOf($db, $rule["ao_group"]);
	if (empty($res))
		return "???";
	else
		list($type,$acobjs) = $res;
	$q = "select * from Acad_object_groups where id=%d";
	$grp = dbOneTuple($db, mkSQL($q,$rule["ao_group"]));
	$text = "";
	switch ($type) {
	case "subject":
		$uoc = uoc($rule["min"],$rule["max"],$grp);
		if ($rule["type"] == "MR" || $rule["type"] == "LR")
			$text = "must complete $uoc before undertaking $acobjs[0]";
		elseif (count($acobjs) == 1)
			$text = $acobjs[0];
		elseif ($uoc != "one of") {
			$text = "$uoc from ".shortish($grp,$acobjs);
		}
		else
			$text = "$uoc ".join(" or ",$acobjs);
		break;
	case "stream":
		if (count($acobjs) == 1)
			$text = "the stream ".$acobjs[0];
		else
			$text = "one of the streams ".join(",",$acobjs);
		break;
	case "program":
		if (count($acobjs) == 1)
			$text = "the program ".$acobjs[0];
		else
			$text = "one of the programs ".join(",",$acobjs);
		break;
	case "requirement":
		$text = "Nested rule?"; // should not occur?
		break;
	}
	return $text;
}

// give a relatively short name for
//   a potentially very long list of academic objects
function shortish($aogroup,$acobjs)
{
	$name = $aogroup["name"];
	$defn = $aogroup["definition"];
	$n = count($acobjs);
	if ($n < 6)
		$res = join(",",$acobjs);
	else {
		if ($aogroup["gdefby"] == "pattern")
			$res = $defn;
#		elseif (!empty($name)) // most names are not useful
#			$res = $name;
		elseif (!empty($defn))
			$res = $defn;
		else
			$res = "(".join(",",array_slice($acobjs,0,5)).",...(".($n-5)." more))";
	}
	return $res;
}

// return a short name for the rule

function ruleName($db, $rid)
{
	$q = "select name from Rules where id=%d";
	$name = dbOneValue($db, mkSQL($q, $rid));
	return empty($name) ? "Rule #$rid" : $name;
}

?>
