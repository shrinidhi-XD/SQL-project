drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product (product_id integer,product_name nvarchar(max),price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;


--what is the total amount spent by each customer on zomato?

select a.userid,sum(b.price) as total_amt from sales a inner join product b on a.product_id = b.product_id group by userid;

--how many days each customer visited

select userid,count(distinct created_date) as distinct_no_days from sales group  by userid;

--what was the first product purchased by the each customer

select * from
(select * , rank() over( partition by userid order by created_date) rank from sales) a where rank=1

--what is the most ordered item on the menu and how many times it was purchased by all the customer

select * from sales
select userid,count(product_id) as most_No_Orders from sales where product_id =
(select top 1 product_id from sales group by product_id order by count(product_id) desc ) group by userid

--which most popular item on the menu for each customer

select * from
(select * ,rank() over (partition by userid order by cnt desc) rnk from
(select userid,product_id, count(product_id) as cnt from sales group by userid,product_id)a)b where rnk=1

--which item did the customers bought after they had goldusers subscription
select * from
(select a. *, dense_rank() over(partition by userid order by created_date) rnk from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b on a.userid=b.userid 
and  created_date>=gold_signup_date)a)b where rnk=1


--which item did the customers bought before they had goldusers subscription
select * from
(select a. *, dense_rank() over(partition by userid order by created_date desc) rnk from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b on a.userid=b.userid 
and  created_date<=gold_signup_date)a)b where rnk=1


-- what is the total order and amount spent by the customer before they became a member?

select userid,count(created_date)as orders_purchased,sum(price) as total_amt_spent from
(select a. *,b.price from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b on a.userid=b.userid 
and  created_date<=gold_signup_date) a inner join product b on a.product_id=b.product_id)c group by userid;


--if buying each product generates points for eg 5rs=2 zom point and each product has diff purchasing points eg P1- 5rs=1, P2 10rs=5,P3-5rs=1 zom point
--cal the points coll by each customers and for which product most points have been till now

select userid,sum(no_zom_points) *2.5 as total_money_earned_CB from
(select c.*, total_amt/points as no_zom_points  from
(select b. *, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 1 else 0 end as points from
(select a.userid,a.product_id,sum(a.price) as total_amt from
(select a. *, b.price from sales a inner join product b on a.product_id=b.product_id)a
group by a.userid,a.product_id)b)c)d group by userid;

select f.* from
(select e.*, rank() over(order by  zom_points desc) rnk from 
(select product_id,sum(no_zom_points) zom_points from
(select c.*, total_amt/points as no_zom_points  from
(select b. *, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 1 else 0 end as points from
(select a.userid,a.product_id,sum(a.price) as total_amt from
(select a. *, b.price from sales a inner join product b on a.product_id=b.product_id)a
group by a.userid,a.product_id)b)c)d group by product_id)e)f where rnk =1;

--In the first one year after the customer joins the gold program (including their joining date) irrespective of what the customer has purchased they earn
-- 5 zom points for every 10 rs spent who earned more 1 or 3 and what was their points earnings in the first year?
=1zom=2rs
1rs=0.5zompoints

select c.* ,d.price *0.5 as total_points_earned from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b on a.userid=b.userid
and created_date>=gold_signup_date and created_date<=DATEADD(year,1,gold_signup_date))c inner join product d on c.product_id=d.product_id




--Rank all the transactions of the customer.

select *,DENSE_RANK() over(partition by userid order by created_date) rnk from sales


--rank all the transactions for each member whenver they are they are zom gold member for every non gold member transaction mark as	NA

select b. *, case when rnk = 0 then 'NA' else rnk  end as rnkk  from
(select a.*, cast((case when gold_signup_date is null then 0 else rank() over(partition by userid order by created_date desc) end ) as varchar) as rnk from
(select a. *, b.gold_signup_date from sales a left join  goldusers_signup b on a.userid=b.userid and created_date>=gold_signup_date)a)b;