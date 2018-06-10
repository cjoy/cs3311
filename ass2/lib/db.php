<?
// COMP3311 18s1 Assignment 2
// COMP3311 Database access library

# dbConnect(connector)
# - establish connection to DB specified in connector string
# - if any errors, terminates with error message

function dbConnect($connector)
{
	$db = pg_connect($connector);
	if (!$db) _dbError("Can't connect to database ($connector)");
	return $db;
}

# dbQuery(db,sql)
# - send an SQL statement to the databas for processing
# - returns handle to the result
# - the SQL statement can be an update, as well as a query

function dbQuery($db,$sql)
{
	if (!is_resource($db)) _dbError("dbQuery: Invalid database object");
	$res = pg_exec($db,$sql);
	if (!$res) _dbError("Query failed\n$sql");
	return $res;
}

# dbNext(res)
# - fetch next tuple from result set
# - default returns tuple as column-name indexed array
# - can also return as integer-indexed array or PHP object

function dbNext($res,$style="hash")
{
	if (!is_resource($res)) _dbError("dbNext: Invalid result object");
	switch ($style) {
	case "row": return pg_fetch_row($res); break;
	case "obj": return pg_fetch_object($res); break;
	default:    return pg_fetch_array($res); break;
	}
}

# dbOneValue(db,sql)
# - execute a query to fetch a single value, and return that value

function dbOneValue($db,$sql,$style="hash")
{
	$t = dbOneTuple($db,$sql,$style);
	return $t[0];
}

# dbOneTuple(db,sql)
# - execute a query to fetch a single tuple, and return that tuple

function dbOneTuple($db,$sql,$style="hash")
{
	$res = dbQuery($db,$sql,$style);
	return dbNext($res);
}

# dbAllTuples(db,sql)
# - execute a query to fetch all results into an array

function dbAllTuples($db,$sql,$style="hash")
{
	$res = dbQuery($db,$sql,$style);
	$tuples = array();
	while ($t = dbNext($res,$style)) $tuples[] = $t;
	return $tuples;
}

# dbUpdate(db,sql)
# - perform update and return how many rows affected

function dbUpdate($db,$sql)
{
	$res = dbQuery($db,$sql);
	$nrows = dbNresults($res);
	return $nrows;
}

# dbNresults(res)
# - returns number of tuples in a result set

function dbNresults($res)
{
	if (!is_resource($res)) _dbError("dbNresults: Invalid result object");
	return pg_num_rows($res);
}

# dbNchanges(res)
# - return count of how many tuples changed (via dbQuery)

function dbNchanges($res) {
	if (!is_resource($res)) _dbError("dbNchanges: Invalid result object");
	return pg_affected_rows($res);
}

# mkSQL:
# - build an SQL query string from a printf-like format statement,
#   ensuring that values are properly quoted for passing to PostgreSQL
# - also converts PHP (null) value into SQL (null)
# - e.g. input:  mkSQL("select * from R where a=%d and b=%s",1,"it's")
#        output: "select * from R where a=1 and b='it''s'
function mkSQL()
{
	$argv = func_get_args();
	$a = 1;
	$q = preg_split('//', $argv[0], -1, PREG_SPLIT_NO_EMPTY);
	$n = count($q);
	$sql = ""; $nerrs = 0;
	for ($i = 0; $i < $n; $i++)
	{
		$c = $q[$i];
		if ($c == "\\")
			$sql .= $q[++$i];
		elseif ($c != "%")
			$sql .= $c;
		else {
			$i++;
			switch ($q[$i]) {
			// String
			case 's':
				$v = trim($argv[$a++]);
				if (empty($v))
					$sql .= "null";
				else {
					$v = pg_escape_string($v);
					if (strchr($v,"\\") !== false)
						$sql .= "E'{$v}'";
					else
						$sql .= "'{$v}'";
				}
				break;
			// Numeric (decimal/float)
			case 'd':
			case 'f':
				$v = $argv[$a++];
				if (empty($v))
					$sql .= "null";
				else {
					if ($c == 'd')
						$v = intval("$v");
					else
						$v = floatval("$v");
					$sql .= $v;
				}
				break;
			case '%':
				$sql .= '%';
				break;
			// Boolean
			case 'b':
				$v = $argv[$a++];
				$tf = truth_value($v);
				if (is_null($tf))
					$sql .= "null";
				elseif ($tf == 't')
					$sql .= "TRUE";
				elseif ($tf == 'f')
					$sql .= "FALSE";
				else {
					$sql .= $v;
					$nerrs++;
				}
				break;
			// Patterns
			case 'p':
				$v = $argv[$a++];
				if (empty($v))
					$sql .= "'%'";
				else {
					$v = pg_escape_string($v);
					if (strchr($v,"\\") !== false)
						$sql .= "E'%{$v}%'";
					else
						$sql .= "'%{$v}%'";
				}
				break;
			// Literals ... only use this for
			//              internally-generated strings
			// If arg has no value, generate invalid SQL
			case 'L':
				$v = trim($argv[$a++]);
				if (!empty($v)) {
					$sql .= $v;
				}
				break;
			default:
				$nerrs++;
			}
		}
	}
	if ($nerrs > 0) _dbError($sql);
	return $sql;
}

function truth_value($val)
{
	if (!isset($val)) return null;
	if ($val === true)
		return 't';
	elseif ($val === false)
		return 'f';
	$val = strtolower(substr($val,0,1));
	if ($val == 't' || $val == 'y')
		return 't';
	elseif ($val == 'f' || $val == 'n')
		return 'f';
	else
		return $val;
}


# _dbError(msg)
# - print error message and backtrace, then terminate script

function _dbError($msg)
{
	$msg .= "\n";
	$trace = debug_backtrace();
	foreach ($trace as $ref) {
		if ($ref["function"] == "db_trace" ||
			$ref["function"] == "_dberror") continue;
		if (array_key_exists("file",$ref))
			$msg .= "in '$ref[file]'";
		if (array_key_exists("file",$ref))
			$msg .= ", line $ref[line]";
		if (array_key_exists("file",$ref))
			$msg .= ", $ref[function](";
		if (array_key_exists("args",$ref)) {
			$args = array();
			foreach ($ref["args"] as $a)
			$arg[] = strval($a);
			$msg .= join(",",$args);
		}
		if (array_key_exists("file",$ref))
			$msg .= ")";
		$msg .= "\n";
	}
	exit ("$msg\n");
}

?>
