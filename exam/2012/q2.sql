-- COMP3311 12s1 Exam Q2
-- The Q2 view must have one attribute called (player,goals)

drop view if exists Q2;
create view Q2
as
select p.name as player, count(g.scoredIn) as goals
from players p, goals g
where g.rating='amazing' and g.scoredBy=p.id
group by p.name
having count(g.scoredIn)>1;

