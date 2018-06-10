-- COMP3311 12s1 Exam Q3
-- The Q3 view must have attributes called (team,players)

drop view if exists Q3;
create view Q3
as
select t.country as team, count(p.memberOf) as players
from players p, teams t
where p.id not in (select scoredBy from goals)
and t.id=p.memberOf
group by p.memberOf
order by players desc
limit 1;

