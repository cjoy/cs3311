-- COMP3311 12s1 Exam Q1
-- The Q1 view must have attributes called (team,matches)

drop view if exists Q1;
create view Q1
as
select t.country as team, count(t.id) as matches
from teams t, involves i
where t.id=i.team
group by t.country;
