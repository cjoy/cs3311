CREATE OR REPLACE FUNCTION public.transcript(_sid integer)
RETURNS SETOF transcriptrecord
LANGUAGE plpgsql
AS $function$
declare
   rec TranscriptRecord;
   UOCtotal integer := 0;
   UOCpassed integer := 0;
   wsum integer := 0;
   wam integer := 0;
   x integer;
begin
   select s.id into x
   from   Students s join People p on (s.id = p.id)
   where  p.unswid = _sid;
   if (not found) then
           raise EXCEPTION 'Invalid student %',_sid;
   end if;
   for rec in
      select su.code,
          substr(t.year::text,3,2)||lower(t.term),
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
            -- only counts towards creditted UOC
            -- if they passed the course
            UOCpassed := UOCpassed + rec.uoc;
         end if;
         -- we count fails towards the WAM calculation
         UOCtotal := UOCtotal + rec.uoc;
         -- weighted sum based on mark and uoc for course
         wsum := wsum + (rec.mark * rec.uoc);
         -- don't give UOC if they failed
         if (rec.grade not in ('PT','PC','PS','CR','DN','HD','A','B','C')) then
                 rec.uoc := 0;
         end if;

      end if;
      return next rec;
   end loop;
   if (UOCtotal = 0) then
           rec := (null,null,'No WAM available',null,null,null);
   else
           wam := wsum / UOCtotal;
           rec := (null,null,'Overall WAM',wam,null,UOCpassed);
   end if;
   -- append the last record containing the WAM
   return next rec;
end;
$function$