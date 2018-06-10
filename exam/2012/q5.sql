-- COMP3311 12s1 Exam Q5
-- The Q5 view must have attributes called (team,reds,yellows)

drop view if exists CountryCards;
create view CountryCards
as
select t.country as country, c.cardType as color, count(c.cardType) as cards
from teams t
join players p on (p.memberOf = t.id)
join cards c on (c.givenTo=p.id)
group by t.country, c.cardType
;

drop view if exists CountryRedCards;
create view CountryRedCards
as
select c.country as country, cards as cards
from countryCards c
join teams t on (c.country=t.country)
where color='red';

drop view if exists CountryYellowCards;
create view CountryYellowCards
as
select c.country as country, cards as cards
from countryCards c
join teams t on (c.country=t.country)
where color='yellow';

drop view if exists Q5;
create view Q5
as
select t.country, coalesce(rc.cards,0), coalesce(yc.cards,0)
from teams t
left join CountryRedCards rc on (rc.country=t.country)
left join CountryYellowCards yc on (yc.country=t.country);
