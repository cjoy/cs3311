-- COMP3311 12s1 Exam Q6
-- The Q6 view must have attributes called
-- (location,date,team1,goals1,team2,goals2)

-- function that take in matchid and country and outputs goals
drop view if exists MatchGoals;
create view MatchGoals
as
select g.scoredIn as match, p.memberOf as team, count(*) as goals
from goals g
join players p on (p.id=g.scoredBy)
group by g.scoredIn, p.memberOf
;

drop view if exists Q6;
create view Q6
as
select m.id,
	m.city as location, m.playedOn as date, 
	t1.country as team1,
	(select mg1.goals from matchgoals mg1 where mg1.match=m.id and mg1.team=t1.id),
	t2.country as team2,
	(select mg2.goals from matchgoals mg2 where mg2.match=m.id and mg2.team=t2.id)
from matches m
join involves i1 on (i1.match=m.id)
join involves i2 on (i2.match=m.id)
join teams t1 on (t1.id=i1.team)
join teams t2 on (t2.id=i2.team)
where t1.country < t2.country
;
