-- COMP3311 12s1 Exam Q4
-- The Q4 view must have attributes called (team1,team2,matches)

drop view if exists MatchList;
create view MatchList
as
select t1.country as team1, t2.country as team2, count(*) as matches
from matches m
	join involves i1 on (i1.match=m.id)
	join involves i2 on (i2.match=m.id)
	join teams t1 on (t1.id=i1.team)
	join teams t2 on (t2.id=i2.team)
where t1.country < t2.country
group by t1.country, t2.country
order by count(*)
;

drop view if exists Q4;
create view Q4
as
select * 
from MatchList 
where matches = (select max(matches) from MatchList)
;
