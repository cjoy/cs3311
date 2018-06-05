/* CS3311, Assignment 1 ~ Chris Joy, z5113243 */


/* Q1 */

create or replace view Q1(unswid, name)
as
    select p.unswid as unswid, p.name as name
    from people p, course_enrolments ce
    where ce.student = p.id
    group by p.id
    having count(*) > 65;
;

/* Q2 */

create or replace view nstudents(count)
as
    select count(*)
    from students
    left join staff on students.id = staff.id
    where staff.id is null;
;
create or replace view nstaff(count)
as
    select count(*)
    from staff
    left join students on students.id = staff.id
    where students.id is null;
;
create or replace view nboth(count)
as
    select count(*)
    from staff
    left join students on students.id = staff.id
    where students.id is not null
    and staff.id is not null;
;
create or replace view Q2(nstudents, nstaff, nboth)
as
    select nstudents.count as nstudents, nstaff.count as nstaff, nboth.count as nboth
    from nstudents, nstaff, nboth;
;

/* Q3 */

create or replace view course_convenors(name, ncourses)
as
    select people.name as name, count(*) as ncourses
    from people, course_staff, staff_roles
    where staff_roles.name = 'Course Convenor'
	    and course_staff.role = staff_roles.id
	    and people.id = course_staff.staff
    group by people.id;
;
create or replace view Q3(name, ncourses)
as
    select course_convenors.name as name, course_convenors.ncourses as ncourses
    from course_convenors
    where course_convenors.ncourses = (
        select max(course_convenors.ncourses)
        from course_convenors
    );
;

/* Q4 */

create or replace view Q4a(id)
as
    select people.unswid as id
    from people, program_enrolments, programs, semesters
    where programs.code = '3978'
        and program_enrolments.program = programs.id
        and program_enrolments.student = people.id
        and program_enrolments.semester = semesters.id
        and semesters.year = 2005
        and semesters.term = 'S2';
;
create or replace view Q4b(id)
as
    select people.unswid as id
    from people, program_enrolments, streams, semesters, stream_enrolments
    where streams.code = 'SENGA1'
        and stream_enrolments.stream = streams.id
        and program_enrolments.id = stream_enrolments.partof
        and program_enrolments.student = people.id
        and program_enrolments.semester = semesters.id
        and semesters.year = 2005
        and semesters.term = 'S2';
;
create or replace view Q4c(id)
as
    select people.unswid as id
    from people, program_enrolments, semesters, orgunits, programs
    where orgunits.unswid = 'COMPSC'
        and programs.offeredby = orgunits.id
        and program_enrolments.program = programs.id
        and program_enrolments.student = people.id
        and program_enrolments.semester = semesters.id
        and semesters.year = 2005
        and semesters.term = 'S2';
;

/* Q5 */

create or replace function org_name(integer) returns text
as $$
    select orgunits.name as name from orgunits where orgunits.id = $1
$$ language sql
;
create or replace view faculty_committee_count(faculty, count)
as
	select facultyOf(id) as faculty, count(*)
	from orgunits
	where orgunits.utype = (
		select id from orgunit_types where orgunit_types.name='Committee'
	)
	and facultyOf(id) > 0
	group by facultyOf(id);
;
create or replace view Q5(name)
as
	select org_name(faculty) as name
	from faculty_committee_count
	where count = (select max(count) from faculty_committee_count);
;

/* Q6 */

create or replace function Q6(integer) returns text
as $$
    select people.name
    from people
    where people.id = $1
        or people.unswid = $1;
$$ language sql
;

/* Q7 */

create or replace function Q7(text)
	returns table (course text, year integer, term text, convenor text)
as $$
    select cast(subjects.code as text), semesters.year, cast(semesters.term as text), Q6(course_staff.staff)
    from courses, subjects, course_staff, semesters
    where subjects.code = $1
        and courses.subject = subjects.id
        and course_staff.course = courses.id
        and courses.semester = semesters.id
        and course_staff.role = (
            select id from staff_roles where name='Course Convenor'
        );
$$ language sql
;

/* Q8 */

create or replace function student_enrolment_code(integer, integer) returns char
as $$
    select programs.code
    from program_enrolments, programs, people
    where people.unswid = $1
        and program_enrolments.student = people.id
        and program_enrolments.semester = $2
        and programs.id = program_enrolments.program;
$$ language sql
;
CREATE OR REPLACE FUNCTION q8(_sid integer)
    RETURNS SETOF NewTranscriptRecord
    LANGUAGE plpgsql
AS $function$
declare
   rec NewTranscriptRecord;
   UOCtotal integer := 0;
   UOCpassed integer := 0;
   wsum integer := 0;
   wam integer := 0;
   x integer;
begin
    select s.id into x
    from Students s join People p on (s.id = p.id)
    where p.unswid = _sid;
    if (not found) then
        raise EXCEPTION 'Invalid student %',_sid;
    end if;
    for rec in
        select su.code,
            substr(t.year::text,3,2)||lower(t.term),
            student_enrolment_code(_sid, t.id),
            substr(su.name,1,20),
            e.mark, e.grade, su.uoc
        from   People p
            join Students s on (p.id = s.id)
            join Course_enrolments e on (e.student = s.id)
            join Courses c on (c.id = e.course)
            join Subjects su on (c.subject = su.id)
            join Semesters t on (c.semester = t.id)
        where  p.unswid = _sid
        order  by t.starting, su.code
    loop
        if (rec.grade = 'SY') then
            UOCpassed := UOCpassed + rec.uoc;
        elsif (rec.mark is not null) then
            if (rec.grade in ('PT','PC','PS','CR','DN','HD','A','B','C')) then
            UOCpassed := UOCpassed + rec.uoc;
            end if;
            UOCtotal := UOCtotal + rec.uoc;
            wsum := wsum + (rec.mark * rec.uoc);
            if (rec.grade not in ('PT','PC','PS','CR','DN','HD','A','B','C')) then
                rec.uoc := 0;
            end if;
        end if;
        return next rec;
    end loop;
    if (UOCtotal = 0) then
        rec := (null,null,null,'No WAM available',null,null,null);
    else
        wam := wsum / UOCtotal;
        rec := (null,null,null,'Overall WAM',wam,null,UOCpassed);
    end if;
    return next rec;
end;
$function$
;

/* Q9 */

create or replace function replace_regex_code(text) returns text
as $$
    select REGEXP_REPLACE(
        REGEXP_REPLACE($1,',','|','g')
    ,'#','[a-zA-Z0-9]','g');
$$ language sql
;
create or replace function Q9(_gid integer)
	returns setof AcObjRecord
as $$
declare
   rec AcObjRecord;
   _type text;
begin
    select gtype into _type
    from acad_object_groups
    where id = _gid;

    if _type = 'subject' then
        for rec in
            select distinct a.gtype, su.code
            from acad_object_groups a, subjects su
            where a.id = _gid
            and a.definition !~ '{.*}'
            and su.code ~ replace_regex_code(a.definition)
            and a.gdefby = 'pattern'
            order by su.code
        loop
            return next rec;
        end loop;
    elsif _type = 'stream' then
        for rec in
            select distinct a.gtype, su.code
            from acad_object_groups a, streams su
            where a.id = _gid
            and a.definition !~ '{.*}'
            and su.code ~ replace_regex_code(a.definition)
            and a.gdefby = 'pattern'
            order by su.code
        loop
            return next rec;
        end loop;
    elsif _type = 'program' then
        for rec in
            select distinct a.gtype, su.code
            from acad_object_groups a, programs su
            where a.id = _gid
            and a.definition !~ '{.*}'
            and su.code ~ replace_regex_code(a.definition)
            and a.gdefby = 'pattern'
            order by su.code
        loop
            return next rec;
        end loop;
    end if;
end;
$$ language plpgsql
;