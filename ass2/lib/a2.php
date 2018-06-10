<?php
// COMP3311 18s1 Assignment 2
// Functions for assignment Tasks A-E
// Written by Christopher Joy (z5113243), May 2018

// assumes that defs.php has already been included


// Task A: get members of an academic object group

// E.g. list($type,$codes) = membersOf($db, 111899)
// Inputs:
//  $db = open database handle
//  $groupID = acad_object_group.id value
// Outputs:
//  array(GroupType,array(Codes...))
//  GroupType = "subject"|"stream"|"program"
//  Codes = acad object codes in alphabetical order
//  e.g. array("subject",array("COMP2041","COMP2911"))

function membersOf($db,$groupID)
{
    $q = "select * from acad_object_groups where id = %d";
    $group = dbOneTuple($db, mkSQL($q, $groupID));
    $codes = array();

    switch ($group["gdefby"]) {
    /* Enumerated Codes */
    case "enumerated":
        $q = "select code from ".$group["gtype"]."_group_members, "
            .$group["gtype"]."s where ".$group["gtype"]
            ."_group_members.ao_group = ".$groupID." and "
            .$group["gtype"]."s.id = ".$group["gtype"]."_group_members.".$group["gtype"];
        $res = dbQuery($db, $q); 
        while ($tup = dbNext($res)) {
            array_push($codes, $tup["code"]);
        }
        break;
    /* Pattern Codes */ 
    case "pattern":
        $def = str_replace("{", "", $group["definition"]);
        $def = str_replace(";", ",", $def);
        $def = str_replace("}", "", $def);
        foreach (explode(",", $def) as $pat) {
            if (preg_match("/^(GENG|GEN#|FREE|####|all|ALL)/", $pat)) {
                array_push($codes, $pat);
            } else {
                $pat = str_replace("#", ".", $pat);
                // lookup codes using pat
                $q = "select code from ".$group["gtype"]."s where code ~ %s";
                $res = dbQuery($db, mkSQL($q, $pat));
                while ($tup = dbNext($res)) {
                    array_push($codes, $tup["code"]);
                }
            }
        }
        break;
    /* Query Codes */
    case "query":
        $q = $group["definition"];
        $res= dbQuery($db, mkSql($q));
        while ($tup = dbNext($res)) {
            array_push($codes, $tup["code"]);
        }
    }

    // Recursively collect subgroups
    $q = "select id from acad_object_groups where parent = %d";
    $res = dbQuery($db, mkSQL($q, $groupID));
    while ($tup = dbNext($res)) {
        $subcodes = membersOf($db, $tup["id"]);
        $codes = array_merge($codes, $subcodes[1]);
    }

    sort($codes);
    return array($group["gdefby"], $codes);
}

// Task B: check if given object is in a group

// E.g. if (inGroup($db, "COMP3311", 111938)) ...
// Inputs:
//  $db = open database handle
//  $code = code for acad object (program,stream,subject)
//  $groupID = acad_object_group.id value
// Outputs:
//  true/false

// TODO: case: /F= and !
function inGroup($db, $code, $groupID)
{
    $membersOf = membersOf($db, $groupID);
    $codes = $membersOf[1];

    $q = "select * from acad_object_groups where id = %d";
    $group = dbOneTuple($db, mkSQL($q, $groupID));
    // query string for code
    $q = "select code from ".$group["gtype"]."s where code ~ %s";

    // check each pattern  
    foreach ($codes as $pat) {
        // include any subject whose first three characters are not "GEN"
        if (preg_match("/^(FREE|####|all|ALL)/", $pat)) {
            //echo $pat."\n";
            $pat = preg_replace("/FREE/", "^((?!GEN).)*", $pat);
            $pat = preg_replace("/#+$/", "[0-9]+", $pat); // replace last #'s with nums
            $pat = str_replace("#", ".", $pat);
            //echo $pat."\n";
            $res = dbQuery($db, mkSQL($q, $pat));
            while ($tup = dbNext($res)) {
                array_push($codes, $tup["code"]);
            }
        }
        // include any subject whose first three characters are "GEN"
        elseif (preg_match("/^GEN(G|#)/", $pat)) {
            $pat = "^GEN.*";
            $res = dbQuery($db, mkSQL($q, $pat));
            while ($tup = dbNext($res)) {
                array_push($codes, $tup["code"]);
            }
        }
        // includes any subject whose first three characters are "GEN"
        // and which is offered by the Science Faculty or some school under the Science Faculty
        elseif (preg_match("/^(GENG####\/F=SCI)/", $pat)) {
            //TODO
        }
    }

    return in_array($code, $codes);;
}


// Task C: can a subject be used to satisfy a rule

// E.g. if (canSatisfy($db, "COMP3311", 2449, $enr)) ...
// Inputs:
//  $db = open database handle
//  $code = code for acad object (program,stream,subject)
//  $ruleID = rules.id value
//  $enr = array(ProgramID,array(StreamIDs...))
// Outputs:

// TODO: check if stream starting with GEN is allowed
function canSatisfy($db, $code, $ruleID, $enrolment)
{
    $status = false;

    // get aog for given rule
    $rule = dbOneTuple($db, "select * from rules where id=".$ruleID);
    // return false if no aog
    if (!$rule[ao_group]) return false;

    // check if it's in ao_group
    $status = inGroup($db, $code, $rule[ao_group]);

    // GenEd subjects need an extra check - check prog/stream faculty
    if (preg_match("/^GEN/", $code) and $status) {
        // generate faculities array from stream(s) / program
        $faculties = array();
        foreach ($enrolment[1] as $streamId) {
            $q = "select facultyof(offeredBy) as id from streams where id =".$streamId;
            $faculty = dbOneTuple($db,$q);
            array_push($faculties, $faculty[id]);
        }
        $q = "select facultyof(offeredBy) as id from programs where id =".$enrolment[0];
        $faculty = dbOneTuple($db,$q);
        array_push($faculties, $faculty[id]);

        // check if faculty allows for gened
        // ie. stream/subject_fac as facultyId != program/stream_fac
        $qSubject = "select facultyof(offeredBy) as id from subjects where code = '".$code."'";
        $subject = dbOneTuple($db, $qSubject);
        $qStream = "select facultyof(offeredBy) as id from streams where code = '".$code."'";
        $stream = dbOneTuple($db, $qStream);
        foreach ($faculties as $facultyId) {
            if ($subject[id] == $facultyId or $stream[id] == $facultyId) {
                $status = false;
            }
        }

    }
    return $status;
}


// Task D: determine student progress through a degree

// E.g. $vtrans = progress($db, 3012345, "05s1");
// Inputs:
//  $db = open database handle
//  $stuID = People.unswid value (i.e. unsw student id)
//  $semester = code for semester (e.g. "09s2")
// Outputs:
//  Virtual transcript array (see spec for details)

function getAttr($db, $table, $o_attr_key, $i_attr_key, $i_attr_val, $mask) {
    $q = "select ".$o_attr_key." from ".$table." where ".$i_attr_key."=".$mask.$i_attr_val.$mask;
    $res = dbOneTuple($db, $q);
    return $res[$o_attr_key];
}

// 1. get complete student record using transcript
// 2. get a list of requirements from program/stream
// 3. tick off completed requirements from list (in 2)
function progress($db, $stuID, $term)
{
    // 1. collect student transcript until perticular semester
    $courses = collectCourseEnrolments_1($db, $stuID, $term);
    $marks = array_pop($courses);
    foreach ($courses as $course) {
        if ($course[3] == 0) unset($course[0]); 
    }
    // debug
    //foreach ($courses as $t) { echo $t[0]." - ".$t[1]." - ".$t[2]." - ".$t[3]." - ".$t[4]." - ".$t[5]."\n"; }
    // collect student program / stream ids 
    $program_streams = collectProgStrmEnrolments_1($db, $stuID, $term);
    $last_ps = array_pop($program_streams);
    $program = getAttr($db, "programs", "id", "code", $last_ps[1], "'");
    $stream = $last_ps[2] == "Unknown" ? null : getAttr($db, "streams", "id", "code", $last_ps[2], "'");
    $enrolment = array($program, array($stream));
    // debug
    //echo "last program - $program    last stream - $stream \n";

    // 2. get a list of rules for program / stream
    $requirements = array("CC", "PE", "FE", "GE", "LR");
    $rules = array();
    $q = "select * from ( "
        ."  (select * from program_rules, rules "
        ."  where program_rules.program=%d "
        ."  and rules.id=program_rules.rule order by rules.id) "
        ." union all "
        ."  (select * from stream_rules, rules "
        ."  where stream_rules.stream=%d "
        ."  and rules.id=stream_rules.rule order by rules.id) "
        .") program_stream_rules "
        ."order by ( case type "
        ." when 'CC' then 1 "
        ." when 'PE' then 2 "
        ." when 'FE' then 3 "
        ." when 'GE' then 4 "
        ." else 5 end "
        ."), rule";
    $res = dbQuery($db, mkSql($q, $program, $stream));
    while ($tup = dbNext($res)) {
        if (in_array($tup[type], $requirements)) array_push($rules, $tup);
    }
    // debug
    //foreach ($rules as $rule) { echo $rule[id]." ".$rule[name]." ".$rule[type]." ".$rule[min]." ".$rule[max]." ".$rule[ao_group]."\n"; }


    // 3. build final array
    // build rules map
    $rules_map = array();    
    foreach ($rules as $rule) {
        $rules_map[$rule[name]] = $rule[min];
    }
    $original_rules_map = $rules_map;

    // build course array
    $assigned = array();
    $completed = array();
    $incomplete = array();
    foreach ($courses as $course) {
        $mkey = $course[0].$course[1]; // unique map key
        $grade = $course[3] == 0 ? null : $course[3]; // tmp mark fix - 0 grade is null
        foreach ($rules as $rule) {
            // fits requirements
            if (
                isset($course[4]) and
                canSatisfy($db, $course[0], $rule["id"], $enrolment)
            ) {
                // if course failed
                if (!in_array($mkey, $assigned) and $course[4] == 'FL') {
                    array_push($assigned, $mkey);
                    array_push($completed, array($course[0], $course[1], $course[2], $grade,
                            $course[4], $course[5], "Failed. Does not count"));
                }
                // otherwise try and fit it with gen edd
                elseif (
                    !in_array($mkey, $assigned) and preg_match("/^GEN/", $course[0]) and
                    $rule[id] == 'GE' and $rules_map[$rule[name]] > 0
                ) {
                    array_push($assigned, $mkey);
                    array_push($completed, array($course[0], $course[1], $course[2], $grade,
                        $course[4], $course[5], $rule[name]));
                    $rules_map[$rule[name]] -= $course[5];
                }
                // assign to free elec
                elseif (!in_array($mkey,$assigned) and $rule[id] == 'FE' and $rules_map[$rule[name]] > 0) {
                    array_push($assigned, $mkey);
                    array_push($completed, array($course[0], $course[1], $course[2], $grade,
                        $course[4], $course[5], $rule[name]));
                    $rules_map[$rule[name]] -= $course[5];
                }
                // otherwise passed
                elseif (!in_array($mkey, $assigned) and isPass_1($course[4]) and $rules_map[$rule[name]] > 0) {
                    array_push($assigned, $mkey);
                    array_push($completed, array($course[0], $course[1], $course[2], $grade, 
                        $course[4], $course[5], $rule[name]));
                    $rules_map[$rule[name]] -= $course[5]; // update uoc
                }
            }
            // hasn't been completed yet
            elseif (!isset($course[4])) {
                if (!in_array($mkey, $assigned)) {
                    array_push($assigned, $mkey);
                    array_push($incomplete, array($course[0], $course[1], $course[2], null, 
                        null, null, "Incomplete. Does not yet count"));
                }
            }
        }
        // if the course hasn't been assigned to a requirement,
        // it may not fit any requirement
        if (!in_array($mkey, $assigned) and isset($course[4])) {
            array_push($assigned, $mkey);
            array_push($completed, array($course[0], $course[1], $course[2], $grade,
                $course[4], $course[5], "Fits no requirement. Does not count"));
        }
    }
    
    // partition array using grades
    $transcript = array_merge($completed, $incomplete);
    $wam = $marks[3] > 0 ? $marks[3] : null;
    $uoc = $marks[5] > 0 ? $marks[5] : null;
    array_push($transcript, array("Overall WAM", $wam, $uoc));
    
    // build need to complete array
    $todo = array();
    foreach ($rules as $rule) {
        if ($rules_map[$rule[name]] > 0) {
            $msg = ($original_rules_map[$rule[name]] - $rules_map[$rule[name]])
                ." UOC so far; need ".$rules_map[$rule[name]]." UOC more";
            array_push($transcript, array($msg, $rule[name]));
        }
    }
    return $transcript;
}


// Task E:

// E.g. $advice = advice($db, 3012345, 162, 164)
// Inputs:
//  $db = open database handle
//  $studentID = People.unswid value (i.e. unsw student id)
//  $currTermID = code for current semester (e.g. "09s2")
//  $nextTermID = code for next semester (e.g. "10s1")
// Outputs:
//  Advice array (see spec for details)


// 1. get student's enrolment info
// 2. get courses they have already taken till the current semester using transcript
// 3. get courses by their 
function advice($db, $studentID, $currTermID, $nextTermID)
{
    echo $currTermID." ".$nextTermID;
    return array(); // stub
}





/* HELPER FUNCTIONS */

// Credits: these helper functions were written by John Sheperd,
// and was taken from the ts php script.

function getProgStrmEnrolments_1()
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

function collectProgStrmEnrolments_1($db, $sid, $tid)
{
        $r = dbQuery($db, mkSQL(getProgStrmEnrolments_1(), $sid, $tid));
        $results = array();
        while ($t = dbNext($r)) {
                list($term, $prog, $strm) = $t;
                $results[] = array($term,$prog,$strm);
        }
        return $results;
}

function collectCourseEnrolments_1($db, $sid, $tid)
{
        // luckily we already have a suitable transcript() function
        $q = "select * from transcript(%d,%d)";
        $r = dbQuery($db, mkSQL($q, $sid, $tid));
        $results = array();
        while ($t = dbNext($r)) {
                list($code,$term,$title,$mark,$grade,$uoc) = $t;
                $mark = is_null($mark) ? "" : sprintf("%d",$mark);
                if (!empty($grade) && !isPass_1($grade)) $uoc = "";
                $uoc = is_null($uoc) ? "" : sprintf("%d",$uoc);
                $results[] = array($code,$term,$title,$mark,$grade,$uoc);
        }
        return $results;
}

function isPass_1($grade)
{
        $passGrades = array("PC"=>1,"PS"=>1,"CR"=>1,"DN"=>1,"HD"=>1,"SY"=>1);
        return(isset($passGrades[$grade]));
}

?>
