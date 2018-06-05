-- COMP3311 18s1 Assignment 1
--
-- check.sql ... checking functions
--

--
-- Helper functions
--

create or replace function
	a1_table_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_class
	where relname=tname and relkind='r';
	return (_check = 1);
end;
$$ language plpgsql;

create or replace function
	a1_view_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_class
	where relname=tname and relkind='v';
	return (_check = 1);
end;
$$ language plpgsql;

create or replace function
	a1_function_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_proc
	where proname=tname;
	return (_check > 0);
end;
$$ language plpgsql;

-- a1_check_result:
-- * determines appropriate message, based on count of
--   excess and missing tuples in user output vs expected output

create or replace function
	a1_check_result(nexcess integer, nmissing integer) returns text
as $$
begin
	if (nexcess = 0 and nmissing = 0) then
		return 'correct';
	elsif (nexcess > 0 and nmissing = 0) then
		return 'too many result tuples';
	elsif (nexcess = 0 and nmissing > 0) then
		return 'missing result tuples';
	elsif (nexcess > 0 and nmissing > 0) then
		return 'incorrect result tuples';
	end if;
end;
$$ language plpgsql;

-- a1_check:
-- * compares output of user view/function against expected output
-- * returns string (text message) containing analysis of results

create or replace function
	a1_check(_type text, _name text, _res text, _query text) returns text
as $$
declare
	nexcess integer;
	nmissing integer;
	excessQ text;
	missingQ text;
begin
	if (_type = 'view' and not a1_view_exists(_name)) then
		return 'No '||_name||' view; did it load correctly?';
	elsif (_type = 'function' and not a1_function_exists(_name)) then
		return 'No '||_name||' function; did it load correctly?';
	elsif (not a1_table_exists(_res)) then
		return _res||': No expected results!';
	else
		excessQ := 'select count(*) '||
			   'from (('||_query||') except '||
			   '(select * from '||_res||')) as X';
		-- raise notice 'Q: %',excessQ;
		execute excessQ into nexcess;
		missingQ := 'select count(*) '||
			    'from ((select * from '||_res||') '||
			    'except ('||_query||')) as X';
		-- raise notice 'Q: %',missingQ;
		execute missingQ into nmissing;
		return a1_check_result(nexcess,nmissing);
	end if;
	return '???';
end;
$$ language plpgsql;

-- a1_rescheck:
-- * compares output of user function against expected result
-- * returns string (text message) containing analysis of results

create or replace function
	a1_rescheck(_type text, _name text, _res text, _query text) returns text
as $$
declare
	_sql text;
	_chk boolean;
begin
	if (_type = 'function' and not a1_function_exists(_name)) then
		return 'No '||_name||' function; did it load correctly?';
	elsif (_res is null) then
		_sql := 'select ('||_query||') is null';
		-- raise notice 'SQL: %',_sql;
		execute _sql into _chk;
		-- raise notice 'CHK: %',_chk;
	else
		_sql := 'select ('||_query||') = '||quote_literal(_res);
		-- raise notice 'SQL: %',_sql;
		execute _sql into _chk;
		-- raise notice 'CHK: %',_chk;
	end if;
	if (_chk) then
		return 'correct';
	else
		return 'incorrect result';
	end if;
end;
$$ language plpgsql;

-- check_all:
-- * run all of the checks and return a table of results

drop type if exists TestingResult cascade;
create type TestingResult as (test text, result text);

create or replace function
	check_all() returns setof TestingResult
as $$
declare
	i int;
	testQ text;
	result text;
	out TestingResult;
	tests text[] := array[
				'q1', 'q2', 'q3', 'q4a', 'q4b', 'q4c', 'q5',
				'q6a', 'q6b', 'q6c', 'q7a', 'q7b', 'q7c', 'q7d',
				'q8a', 'q8b', 'q8c', 'q9a', 'q9b', 'q9c', 'q9d',
				'q9e', 'q9f', 'q9g', 'q9h'
				];
begin
	for i in array_lower(tests,1) .. array_upper(tests,1)
	loop
		testQ := 'select check_'||tests[i]||'()';
		execute testQ into result;
		out := (tests[i],result);
		return next out;
	end loop;
	return;
end;
$$ language plpgsql;


--
-- Check functions for specific test-cases in Assignment 1
--

create or replace function check_q1() returns text
as $chk$
select a1_check('view','q1','q1_expected',
                   $$select * from q1$$)
$chk$ language sql;

create or replace function check_q2() returns text
as $chk$
select a1_check('view','q2','q2_expected',
                   $$select * from q2$$)
$chk$ language sql;

create or replace function check_q3() returns text
as $chk$
select a1_check('view','q3','q3_expected',
                   $$select * from q3$$)
$chk$ language sql;

create or replace function check_q4a() returns text
as $chk$
select a1_check('view','q4a','q4a_expected',
                   $$select * from q4a$$)
$chk$ language sql;

create or replace function check_q4b() returns text
as $chk$
select a1_check('view','q4b','q4b_expected',
                   $$select * from q4b$$)
$chk$ language sql;

create or replace function check_q4c() returns text
as $chk$
select a1_check('view','q4c','q4c_expected',
                   $$select * from q4c$$)
$chk$ language sql;

create or replace function check_q5() returns text
as $chk$
select a1_check('view','q5','q5_expected',
                   $$select * from q5$$)
$chk$ language sql;

create or replace function check_q6a() returns text
as $chk$
select a1_check('function','q6','q6a_expected',
                   $$select * from q6(9334555)$$)
$chk$ language sql;

create or replace function check_q6b() returns text
as $chk$
select a1_check('function','q6','q6b_expected',
                   $$select * from q6(5035569)$$)
$chk$ language sql;

create or replace function check_q6c() returns text
as $chk$
select a1_check('function','q6','q6c_expected',
                   $$select * from q6(12345)$$)
$chk$ language sql;

create or replace function check_q7a() returns text
as $chk$
select a1_check('function','q7','q7a_expected',
                   $$select * from q7('COMP3311')$$)
$chk$ language sql;

create or replace function check_q7b() returns text
as $chk$
select a1_check('function','q7','q7b_expected',
                   $$select * from q7('CHEM2021')$$)
$chk$ language sql;

create or replace function check_q7c() returns text
as $chk$
select a1_check('function','q7','q7c_expected',
                   $$select * from q7('BENV1043')$$)
$chk$ language sql;

create or replace function check_q7d() returns text
as $chk$
select a1_check('function','q7','q7d_expected',
                   $$select * from q7('COMP2411')$$)
$chk$ language sql;

create or replace function check_q8a() returns text
as $chk$
select a1_check('function','q8','q8a_expected',
                   $$select * from q8(3489313)$$)
$chk$ language sql;

create or replace function check_q8b() returns text
as $chk$
select a1_check('function','q8','q8b_expected',
                   $$select * from q8(3430787)$$)
$chk$ language sql;

create or replace function check_q8c() returns text
as $chk$
select a1_check('function','q8','q8c_expected',
                   $$select * from q8(3282281)$$)
$chk$ language sql;

create or replace function check_q9a() returns text
as $chk$
select a1_check('function','q9','q9a_expected',
                   $$select * from q9(1058)$$)
$chk$ language sql;

create or replace function check_q9b() returns text
as $chk$
select a1_check('function','q9','q9b_expected',
                   $$select * from q9(1410)$$)
$chk$ language sql;

create or replace function check_q9c() returns text
as $chk$
select a1_check('function','q9','q9c_expected',
                   $$select * from q9(1121)$$)
$chk$ language sql;

create or replace function check_q9d() returns text
as $chk$
select a1_check('function','q9','q9d_expected',
                   $$select * from q9(2801)$$)
$chk$ language sql;

create or replace function check_q9e() returns text
as $chk$
select a1_check('function','q9','q9e_expected',
                   $$select * from q9(2299)$$)
$chk$ language sql;

create or replace function check_q9f() returns text
as $chk$
select a1_check('function','q9','q9f_expected',
                   $$select * from q9(5825)$$)
$chk$ language sql;

create or replace function check_q9g() returns text
as $chk$
select a1_check('function','q9','q9g_expected',
                   $$select * from q9(2564)$$)
$chk$ language sql;

create or replace function check_q9h() returns text
as $chk$
select a1_check('function','q9','q9h_expected',
                   $$select * from q9(3929)$$)
$chk$ language sql;

--
-- Tables of expected results for test cases
--

drop table if exists q1_expected;
create table q1_expected (
    unswid integer,
    name longname
);

drop table if exists q2_expected;
create table q2_expected (
    nstudents bigint,
    nstaff bigint,
    nboth bigint
);

drop table if exists q3_expected;
create table q3_expected (
    name longname,
    ncourses bigint
);

drop table if exists q4a_expected;
create table q4a_expected (
    id integer
);

drop table if exists q4b_expected;
create table q4b_expected (
    id integer
);

drop table if exists q4c_expected;
create table q4c_expected (
    id integer
);

drop table if exists q5_expected;
create table q5_expected (
    name mediumstring
);

drop table if exists q6a_expected;
create table q6a_expected (
    q6 text
);

drop table if exists q6b_expected;
create table q6b_expected (
    q6 text
);

drop table if exists q6c_expected;
create table q6c_expected (
    q6 text
);

drop table if exists q7a_expected;
create table q7a_expected (
    course text,
    year integer,
    term text,
    convenor text
);

drop table if exists q7b_expected;
create table q7b_expected (
    course text,
    year integer,
    term text,
    convenor text
);

drop table if exists q7c_expected;
create table q7c_expected (
    course text,
    year integer,
    term text,
    convenor text
);

drop table if exists q7d_expected;
create table q7d_expected (
    course text,
    year integer,
    term text,
    convenor text
);

drop table if exists q8a_expected;
create table q8a_expected (
    code character(8),
    term character(4),
    prog character(4),
    name text,
    mark integer,
    grade character(2),
    uoc integer
);

drop table if exists q8b_expected;
create table q8b_expected (
    code character(8),
    term character(4),
    prog character(4),
    name text,
    mark integer,
    grade character(2),
    uoc integer
);

drop table if exists q8c_expected;
create table q8c_expected (
    code character(8),
    term character(4),
    prog character(4),
    name text,
    mark integer,
    grade character(2),
    uoc integer
);

drop table if exists q9a_expected;
create table q9a_expected (
    objtype text,
    object text
);

drop table if exists q9b_expected;
create table q9b_expected (
    objtype text,
    object text
);

drop table if exists q9c_expected;
create table q9c_expected (
    objtype text,
    object text
);

drop table if exists q9d_expected;
create table q9d_expected (
    objtype text,
    object text
);

drop table if exists q9e_expected;
create table q9e_expected (
    objtype text,
    object text
);

drop table if exists q9f_expected;
create table q9f_expected (
    objtype text,
    object text
);

drop table if exists q9g_expected;
create table q9g_expected (
    objtype text,
    object text
);

drop table if exists q9h_expected;
create table q9h_expected (
    objtype text,
    object text
);


COPY q1_expected (unswid, name) FROM stdin;
3012907	Jordan Sayed
3101627	Yiu Man
3137719	Vu-Minh Samarasekera
3139456	Minna Henry-May
3158621	Sanam Sam
3163349	Kerry Plant
3193072	Ivan Tsitsiani
3195354	Marliana Sondhi
\.

COPY q2_expected (nstudents, nstaff, nboth) FROM stdin;
31361	24405	0
\.

COPY q3_expected (name, ncourses) FROM stdin;
Susan Hagon	248
\.

COPY q4a_expected (id) FROM stdin;
3040773
3172526
3144015
3124711
3131729
3173265
3159387
3124015
3126551
3183655
3128290
3192680
\.

COPY q4b_expected (id) FROM stdin;
3032185
3168474
3162463
3171891
3189546
3032240
3074135
3002883
3186595
3062680
3127217
3103918
3176369
3195695
3171566
3137680
3192533
3195008
3104466
3197893
3122796
3171666
3198807
3107927
3109365
3199922
3123330
3145518
3137777
\.

COPY q4c_expected (id) FROM stdin;
2127746
2106821
2101317
2274227
3058210
3002104
3040773
3064466
3039566
3170994
3160054
3066859
3058056
3040854
3032185
3028145
3168474
3162463
3171891
3172526
3044547
3189546
3095209
3032240
3074135
3144015
3071040
3002883
3124711
3186595
3150439
3037496
3038440
3075924
3062680
3003813
3055818
3034183
3113378
3131729
3173265
3127217
3103918
3176369
3118164
3195695
3165795
3159387
3171566
3137680
3192533
3195008
3199764
3119189
3156293
3124015
3126551
3044434
3104466
3197893
3182603
3171417
3183655
3105389
3177106
3152729
3143864
3166499
3107617
3192671
3122796
3171666
3109043
3198807
3125057
3107927
3128290
3109365
3192680
3199922
3159514
3152664
3129900
3123330
3145518
3137777
3179898
3112493
3138098
3162743
\.

COPY q5_expected (name) FROM stdin;
Faculty of Engineering
\.

COPY q6a_expected (q6) FROM stdin;
John Shepherd
\.

COPY q6b_expected (q6) FROM stdin;
John Shepherd
\.

COPY q6c_expected (q6) FROM stdin;
\N
\.

COPY q7a_expected (course, year, term, convenor) FROM stdin;
COMP3311	2003	S1	John Shepherd
COMP3311	2003	S2	Kwok Wong
COMP3311	2006	S1	Wei Wang
COMP3311	2006	S2	John Shepherd
COMP3311	2007	S1	John Shepherd
COMP3311	2007	S2	Wei Wang
COMP3311	2008	S1	John Shepherd
COMP3311	2009	S1	John Shepherd
COMP3311	2010	S1	Xuemin Lin
COMP3311	2011	S1	John Shepherd
COMP3311	2012	S1	John Shepherd
COMP3311	2013	S2	John Shepherd
\.

COPY q7b_expected (course, year, term, convenor) FROM stdin;
CHEM2021	2006	S2	Nick Roberts
CHEM2021	2007	S2	Roger Bishop
CHEM2021	2007	S2	Roger Read
CHEM2021	2007	S2	Jason Harper
CHEM2021	2007	S2	Gavin Edwards
CHEM2021	2008	S2	David Black
CHEM2021	2009	S2	Roger Bishop
CHEM2021	2009	S2	David Black
CHEM2021	2009	S2	Roger Read
CHEM2021	2010	S2	David Black
CHEM2021	2010	S2	Gavin Edwards
CHEM2021	2010	S2	Jason Harper
CHEM2021	2010	S2	Margaret Morris
CHEM2021	2011	S2	Margaret Morris
CHEM2021	2011	S2	Naresh Kumar
CHEM2021	2011	S2	Jason Harper
CHEM2021	2011	S2	Shelli McAlpine
CHEM2021	2011	S2	David Black
CHEM2021	2012	S2	Luke Hunter
CHEM2021	2012	S2	David Black
CHEM2021	2012	S2	Margaret Morris
CHEM2021	2012	S2	Shelli McAlpine
CHEM2021	2012	S2	Naresh Kumar
CHEM2021	2012	S2	Gavin Edwards
CHEM2021	2013	S2	Luke Hunter
CHEM2021	2013	S2	Shelli McAlpine
CHEM2021	2013	S2	Margaret Morris
CHEM2021	2013	S2	Gavin Edwards
CHEM2021	2013	S2	Jason Harper
CHEM2021	2013	S2	David Black
\.

COPY q7c_expected (course, year, term, convenor) FROM stdin;
BENV1043	2002	S1	Dean Utian
BENV1043	2002	S2	Ann Quinlan
BENV1043	2003	S1	Dean Utian
BENV1043	2003	S2	Ann Quinlan
BENV1043	2006	S1	Dean Utian
BENV1043	2006	S2	Dean Utian
BENV1043	2007	S1	Dean Utian
BENV1043	2007	S2	Dean Utian
BENV1043	2008	S1	Dean Utian
BENV1043	2008	S2	Dean Utian
BENV1043	2009	S1	Dean Utian
BENV1043	2009	S2	Dean Utian
BENV1043	2010	X1	Dean Utian
BENV1043	2010	S1	Dean Utian
BENV1043	2010	S2	Dean Utian
BENV1043	2011	S1	Dean Utian
BENV1043	2011	S2	Dean Utian
BENV1043	2012	S2	Dean Utian
BENV1043	2013	S2	Dean Utian
\.

COPY q7d_expected (course, year, term, convenor) FROM stdin;
COMP2411	2003	S1	Eric Martin
\.

COPY q8a_expected (code, term, prog, name, mark, grade, uoc) FROM stdin;
ARTS1750	12s1	3432	Intro to Development	78	DN	6
EDST1101	12s1	3432	Educational Psycholo	80	DN	6
PSYC1001	12s1	3432	Psychology 1A	84	DN	6
PSYC1021	12s1	3432	Intro to Psych Appli	84	DN	6
ARTS1062	12s2	3432	Hollywood Film	75	DN	6
ARTS1871	12s2	3432	Cultural Experience	64	PS	6
CRIM1011	12s2	3432	Intro to Criminal Ju	63	PS	6
PSYC1011	12s2	3432	Psychology 1B	72	CR	6
ARTS2284	13x1	3432	Europe in the Middle	51	PS	6
GENM0518	13x1	3432	Health & Power in In	97	HD	6
\N	\N	\N	Overall WAM	74	\N	60
\.

COPY q8b_expected (code, term, prog, name, mark, grade, uoc) FROM stdin;
LAWS8180	12s1	9240	Principles of Intl L	67	CR	6
POLS5125	12s2	9240	Politics of Internat	84	DN	6
\N	\N	\N	Overall WAM	75	\N	12
\.

COPY q8c_expected (code, term, prog, name, mark, grade, uoc) FROM stdin;
ARTS1091	09s2	3424	Media, Society, Poli	59	PS	6
ARTS1211	09s2	3424	Australia's Asian Co	50	PS	6
MARK1012	09s2	3424	Marketing Fundamenta	60	PS	6
ARTS1811	10s2	3403	International Relati	69	CR	6
ARTS2812	10s2	3403	Politics of Intl Org	69	CR	6
ARTS2842	10s2	3403	Politics of Globalis	79	DN	6
ARTS1210	11s1	3403	Concepts of Asia	80	DN	6
ARTS1810	11s1	3403	Int'l Rel in the 20t	79	DN	6
ARTS2210	11s1	3403	India and South Asia	65	CR	6
ARTS2276	11s1	3403	East Asian History	56	PS	6
ARTS2216	11s2	3403	Politics and Securit	79	DN	6
ARTS2810	11s2	3403	International Relati	68	CR	6
ARTS2813	11s2	3403	International Securi	60	PS	6
GENL1063	11s2	3403	Terror and Religion	72	CR	6
\N	\N	\N	Overall WAM	67	\N	84
\.

COPY q9a_expected (objtype, object) FROM stdin;
subject	COMP2011
subject	COMP2021
subject	COMP2041
subject	COMP2091
subject	COMP2110
subject	COMP2111
subject	COMP2121
subject	COMP2411
subject	COMP2711
subject	COMP2811
subject	COMP2821
subject	COMP2911
subject	COMP2920
\.

COPY q9b_expected (objtype, object) FROM stdin;
subject	CVEN4101
subject	CVEN4102
subject	CVEN4103
subject	CVEN4104
\.

COPY q9c_expected (objtype, object) FROM stdin;
subject	PTRL3001
subject	PTRL3002
subject	PTRL3003
subject	PTRL3015
subject	PTRL3022
subject	PTRL3023
subject	PTRL3025
\.

COPY q9d_expected (objtype, object) FROM stdin;
\.

COPY q9e_expected (objtype, object) FROM stdin;
\.

COPY q9f_expected (objtype, object) FROM stdin;
\.

COPY q9g_expected (objtype, object) FROM stdin;
subject	EDST4170
subject	EDST4171
subject	EDST4172
subject	EDST4173
subject	EDST6700
subject	EDST6701
subject	EDST6702
subject	EDST6703
subject	EDST6704
subject	EDST6705
subject	EDST6706
subject	EDST6707
subject	EDST6708
subject	EDST6709
subject	EDST6710
subject	EDST6711
subject	EDST6712
subject	EDST6713
subject	EDST6714
subject	EDST6715
subject	EDST6716
subject	EDST6717
subject	EDST6718
subject	EDST6719
subject	EDST6720
subject	EDST6721
subject	EDST6722
subject	EDST6723
subject	EDST6724
subject	EDST6725
subject	EDST6726
subject	EDST6727
subject	EDST6728
\.

COPY q9h_expected (objtype, object) FROM stdin;
subject	ARTS1210
subject	ARTS1211
subject	ARTS1270
subject	ARTS1271
subject	ARTS1750
subject	ARTS1751
subject	ARTS1780
subject	ARTS1781
subject	ARTS1810
subject	ARTS1811
subject	ARTS1840
subject	ARTS1841
subject	ARTS2210
subject	ARTS2211
subject	ARTS2212
subject	ARTS2213
subject	ARTS2214
subject	ARTS2215
subject	ARTS2216
subject	ARTS2270
subject	ARTS2271
subject	ARTS2272
subject	ARTS2273
subject	ARTS2274
subject	ARTS2275
subject	ARTS2276
subject	ARTS2277
subject	ARTS2278
subject	ARTS2279
subject	ARTS2280
subject	ARTS2281
subject	ARTS2282
subject	ARTS2283
subject	ARTS2284
subject	ARTS2285
subject	ARTS2286
subject	ARTS2287
subject	ARTS2750
subject	ARTS2751
subject	ARTS2752
subject	ARTS2780
subject	ARTS2781
subject	ARTS2782
subject	ARTS2783
subject	ARTS2785
subject	ARTS2810
subject	ARTS2811
subject	ARTS2812
subject	ARTS2813
subject	ARTS2814
subject	ARTS2815
subject	ARTS2840
subject	ARTS2842
subject	ARTS2843
subject	ARTS2844
subject	ARTS2845
subject	ARTS2846
subject	ARTS2848
subject	ARTS3210
subject	ARTS3211
subject	ARTS3212
subject	ARTS3213
subject	ARTS3214
subject	ARTS3215
subject	ARTS3216
subject	ARTS3218
subject	ARTS3219
subject	ARTS3220
subject	ARTS3270
subject	ARTS3271
subject	ARTS3272
subject	ARTS3273
subject	ARTS3274
subject	ARTS3275
subject	ARTS3276
subject	ARTS3277
subject	ARTS3278
subject	ARTS3279
subject	ARTS3280
subject	ARTS3281
subject	ARTS3282
subject	ARTS3283
subject	ARTS3284
subject	ARTS3285
subject	ARTS3286
subject	ARTS3287
subject	ARTS3288
subject	ARTS3289
subject	ARTS3290
subject	ARTS3291
subject	ARTS3292
subject	ARTS3293
subject	ARTS3294
subject	ARTS3295
subject	ARTS3296
subject	ARTS3750
subject	ARTS3751
subject	ARTS3752
subject	ARTS3753
subject	ARTS3754
subject	ARTS3780
subject	ARTS3781
subject	ARTS3782
subject	ARTS3783
subject	ARTS3784
subject	ARTS3785
subject	ARTS3786
subject	ARTS3810
subject	ARTS3811
subject	ARTS3812
subject	ARTS3813
subject	ARTS3814
subject	ARTS3815
subject	ARTS3816
subject	ARTS3817
subject	ARTS3819
subject	ARTS3841
subject	ARTS3842
subject	ARTS3843
subject	ARTS3844
subject	ARTS3845
subject	ARTS3846
subject	ARTS3847
subject	ARTS3848
subject	ARTS3849
subject	GEOS0310
subject	GEOS0360
subject	GEOS1000
subject	GEOS1111
subject	GEOS1211
subject	GEOS1601
subject	GEOS1701
subject	GEOS1711
subject	GEOS1801
subject	GEOS2001
subject	GEOS2051
subject	GEOS2071
subject	GEOS2101
subject	GEOS2171
subject	GEOS2181
subject	GEOS2241
subject	GEOS2291
subject	GEOS2641
subject	GEOS2711
subject	GEOS2721
subject	GEOS2811
subject	GEOS2821
subject	GEOS3071
subject	GEOS3131
subject	GEOS3141
subject	GEOS3251
subject	GEOS3281
subject	GEOS3300
subject	GEOS3321
subject	GEOS3331
subject	GEOS3341
subject	GEOS3371
subject	GEOS3611
subject	GEOS3621
subject	GEOS3641
subject	GEOS3651
subject	GEOS3711
subject	GEOS3721
subject	GEOS3731
subject	GEOS3761
subject	GEOS3811
subject	GEOS3821
subject	GEOS3911
subject	GEOS3921
subject	GEOS4404
subject	GEOS4411
subject	GEOS4412
subject	GEOS4413
subject	GEOS4415
subject	GEOS4417
subject	GEOS4418
subject	GEOS4721
subject	GEOS6101
subject	GEOS6201
subject	GEOS6202
subject	GEOS6203
subject	GEOS6301
subject	GEOS6302
subject	GEOS6733
subject	GEOS6734
subject	GEOS9001
subject	GEOS9005
subject	GEOS9011
subject	GEOS9012
subject	GEOS9013
subject	GEOS9016
subject	GEOS9017
subject	GEOS9019
subject	GEOS9021
subject	GEOS9023
subject	GEOS9024
subject	GEOS9530
subject	GEOS9632
subject	GEOS9633
subject	GEOS9634
subject	GLST0206
subject	GLST1000
subject	GLST1100
subject	GLST1200
subject	GLST2101
subject	GLST2102
subject	GLST2103
subject	GLST2104
subject	GLST2105
subject	GLST2106
subject	GLST3000
subject	GLST3001
subject	GLST6106
subject	GLST6112
subject	GLST6206
subject	PECO0206
subject	PECO1000
subject	PECO1001
subject	PECO2000
subject	PECO2001
subject	PECO3000
subject	PECO4000
subject	PECO6106
subject	PECO6112
subject	PECO6206
subject	PECO6212
\.

