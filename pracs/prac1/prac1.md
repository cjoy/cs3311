1. How many movies are in the database?
```sql
select count(*) from Movies;
```
2. What are the titles of all movies in the database?
```sql
select Title from Movies;
```

3. What is the earliest year that film was made (in this database)? (Hint: there is a min() summary function)
```sql
select min(Year) from Movies;
```


4. How many actors are there (in this database)?
```sql
select count(*) from Actors;
```


5. Are there any actors whose family name is "Zeta-Jones"? (case-sensitive)
```sql
select givennames||' '||familyname from Actors where familyName='Zeta-Jones';
```


6. What genres are there?
```sql
select distinct(genre) from BelongsTo;
```


7. What movies did Spielberg direct? (title+year)
```sql
select m.title m.year
from Movies m, Directors d, Directs s
where d.familyname='Spielberg' and s.movie=m.id and s.director=d.id;
```


8. Which actor has acted in all movies (in this database)?
```sql

```


9. Are there any directors in the database who don't direct any movies?
```sql

```
