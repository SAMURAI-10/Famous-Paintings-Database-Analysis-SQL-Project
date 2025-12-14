create database famous_paintings;
use famous_paintings;

create table artist
( artist_id  int
, full_name varchar(30)
, first_name varchar(18)
,middle_name varchar(18)
,last_name varchar(18)
,nationality varchar(15)
,style varchar(25)
,birth int
,death int
 );
 
 
 create table museum 
 ( 
 museum_id int
 ,name varchar(60)
 ,address varchar(35)
 ,city varchar(20)
 ,state varchar(30)
 ,postal varchar(50)
 , country varchar(20)
 , phone varchar(20)
 ,url varchar(65)
 );
 
 drop table work;
 create table work
(
 work_id int
,name varchar(60)
,artist_id int
,style varchar(20)
,museum_id int
 );
 
select * from museum ;
select * from canvas_size ;
select * from image_link ;
select * from museum_hours ;
select * from product_size ;
select * from subject ;
select * from canvas_size ;
select * from work;

-- 1.Fetch all paintings which are not displayed on any museums.
select work_id,name,museum_id from work
where museum_id in (null,'',' ');

-- 2.Are there museums without any paintings.
select s.museum_id 
from ( select work_id, m.museum_id 
	from work w right join museum m on w.museum_id = m.museum_id ) s
 where work_id is null;
 
-- 3.how many paintings have an asking price of more than thier regular price
 select count(work_id) from product_size
 where regular_price < sale_Price;
 
 -- 4 Identify the paintings whose asking price is less than 50% of 
 -- its regular price
 select * from product_size
 where sale_price < 0.5*regular_price ;
 
 -- 5 which canvas size costs the most
 select * from 
 canvas_size cs join product_size ps
 on cs.size_id = ps.size_id
 order by ps.sale_price desc
 limit 1;
 
 -- 6 Delete duplicate records from work, product_size,subject and image_link tables
create table workk as 
select distinct * from work;
drop table work;
rename table workk to work;

create table product_sizee as
select distinct * from product_size;
drop table product_size;
rename table product_sizee to product_size;

create table subjectt as
select distinct * from subject;
drop table subject;
rename table subjectt to subject;

create table image_linkk as
select distinct * from image_link;
drop table image_link;
rename table image_linkk to image_link;


 -- 7 Identify the museums with thw invalid city info in the given dataset
 select name,city from museum 
 where city regexp '^[0-9]';
 
 -- 8 Museum_hours table has 1 invalid entry identify it and remove it
 select * from (select *,row_number() over (partition by museum_id,day,open,close) rnk
				from museum_hours ) s
			where s.rnk>1;
            
create table museum_hourss as
select distinct * from museum_hours;
drop table museum_hours;
rename table museum_hourss to museum_hours;
-- 9 Fetch the top 10 most famous paintign subject 
select  subject, count(subject) famous
from subject s
group by s.subject
order by count(subject) desc
limit 10;


-- 10 Identiffy museums which are open on both sunday and monday.display name and city
select m.name ,m.city 
from museum m join museum_hours mh
on m.museum_id=mh.museum_id
where mh.day = 'Sunday' and exists ( 
select * from museum_hours mh2 
where mh.museum_id=mh2.museum_id and mh2.day='Monday'
) ;

select m.name,m.city
from museum m join museum_hours mh
on m.museum_id=mh.museum_id
where mh.day in ('Sunday','Monday')
group by m.museum_id, m.name,m.city
having count(distinct mh.day)=2;

-- 11 How many museums are open every single day
select museum_id 
from museum_hours mh
group by museum_id
having count(distinct day) = 7;

-- 12. Which are the top 5 most popular museum? 
select w.museum_id,m.name ,count(*) work_count
from work w join museum m 
on w.museum_id = m.museum_id 
where w.museum_id != 0
group by w.museum_id,m.name
order by work_count desc
limit 5;

-- 13. Who are the top 5 most popular artist?
select a.full_name,count(*) as total_paintings
from work w join artist a 
on a.artist_id=w.artist_id
group by w.artist_id,a.full_name
order by count(*) desc
limit 5;

-- 14. Display the 3 least popular canva sizes.alte
select cs.size_id,cs.width,cs.height,cs.label,count(*) no_of_work
from work w join product_size ps
on w.work_id = ps.work_id
join canvas_size cs 
on ps.size_id = cs.size_id
group by cs.size_id,cs.width,cs.height,cs.label
order by no_of_work limit 20;

-- 15 Which museum is open for the longest during a day. display museum name ,
-- state and hours open and which day.
select  m.name,m.state,mh.day
,timediff(str_to_date(close,'%h:%i:%p'),str_to_date(open,'%h:%i:%p')) as hours_open
from museum_hours mh join museum m
on mh.museum_id= m.museum_id
order by hours_open desc
limit 1;

-- 16 Which museum has the most number of most popular painting style?
with cte as (
	select style
	from work 
	group by style
	order by count(*) desc
	limit 1 )

select museum_id ,count(*)
from work w join cte
where w.style = cte.style and museum_id != 0
 group by museum_id
 order by count(*) desc
 limit 1;
    
-- 17 Identify teh artists whose paintings are dispalyed in multiple countries.
select a.artist_id,a.full_name ,count(distinct m.country) cnt
from artist a join work w on w.artist_id=a.artist_id
join museum m on m.museum_id=w.museum_id
group by w.artist_id,a.full_name
having count(distinct m.country) >1
order by cnt desc;

-- 18 Display.  the country and the city with the most no of museums output 2 
-- seperate coulumns to mention the city and country 
-- if there aare multiple values seperate them with comma.
with cte1 as (
select country , city,count(*) cnt_museum
from museum
group by country,city)
,
cte2 as (
select max(cnt_museum) cnt
from cte1
)
select country,group_concat(city order by city) as cities
		,cte2.cnt museum_count
	from cte1,cte2
    where cte1.cnt_museum=cte2.cnt
    group by country,cte2.cnt
    order by count(distinct city) desc;

-- 19 Identify the artist and the museum where the most expensive 
-- and least expensive painting is placed 
with cte as(
select a.full_name,m.name,ps.sale_price,rank() over(order by ps.sale_price desc) rnk
from artist a join work w
on w.artist_id=a.artist_id
join product_size ps 
on ps.work_id=w.work_id
join museum m
on m.museum_id=w.museum_id
)
select full_name,name,sale_price,rnk
from cte 
where cte.rnk=1 or rnk= (select max(rnk) from cte)
group by full_name,name,sale_price,rnk;

-- 20 Which country has the 5th highest no of paintings?
with cte as (select m.country , count(*) cnt ,rank() over (order by count(*) desc) rnk
from work w join museum m
on m.museum_id=w.museum_id
group by m.country
) 
select country , cnt
from cte
where cte.rnk= 5;

-- Which are the 3 most popular and 3 least popular painting styles
 (
select (select 'most famous' )as famouse_type ,style, count(*) cnt
from work
where style not in ('',' ')
 group by style 
order by cnt desc
limit 3)
union all
 (
select (select 'least famous') famous_type, style, count(*) cnt
from work

 group by style 
order by cnt 
limit 3);

-- Which artist has the most no. of portrait paintigs outside USA 
-- display artist name , no. of painings and the artist nationality 
with cte as (
select a.full_name artist_name,count(*) paintings_count,a.nationality
,rank() over (order by count(*) desc) rnk 
from artist a join work w
on a.artist_id=w.artist_id
join subject s
on w.work_id=s.work_id
join museum m
on w.museum_id = m.museum_id
where s.subject = 'Portraits' and m.country != 'USA'
group by a.full_name,a.nationality
)
select group_concat(artist_name order by artist_name) ,paintings_count,nationality
from cte 
where rnk =1
group by paintings_count,nationality;
