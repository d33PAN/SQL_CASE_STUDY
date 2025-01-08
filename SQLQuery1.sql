use  punjabi_dhaba
go

-- 1. What is the total amount each customer spent at the restaurant?
----Answer
SELECT
  	sum(menu.price) as price ,sales.customer_id as customer_id from menu join sales on menu.product_id=sales.product_id group by customer_id order by price desc;

-------------------------------------------------------------------------------------------------------------------------------------
-- 2. How many days has each customer visited the restaurant?
--Answer 
  select  count( distinct sales.order_date) as visit , customer_id as name from sales group by customer_id order by visit asc;

----------------------------------------------------------------------------------------------------------------------------------------
-- 3. What was the first item from the menu purchased by each customer?
 --Answer 3  
 SELECT 
    sales.customer_id,
    (SELECT TOP 1 product_name 
     FROM menu 
     JOIN sales s ON menu.product_id = s.product_id
     WHERE s.customer_id = sales.customer_id -- co_related subquery refers to customer_id from ouer query 
     ORDER BY s.order_date ASC) AS first_pick
FROM 
    sales
GROUP BY  sales.customer_id;
---------------------------------------
 select sales.customer_id, (select top 1 product_name from sales s join menu m on s.product_id=m.product_id where s.customer_id=sales.customer_id order  by order_date asc) as first_pick from sales group by sales.customer_id;
 -------------------------------------

 -- another solution using row_number by partition
-- using cte expression a formed function can be used again using a where condition in which function declared in cte can be used directly

with first_menu_cte as (select product_name , order_date , customer_id ,ROW_NUMBER() over ( partition by customer_id order by order_date asc ) as row,
RANK() over (partition by customer_id order by order_date asc ) as rank 
from sales s join menu m on s.product_id=m.product_id  )
select product_name ,customer_id from first_menu_cte where rank =1 and row =1

------------------------------------------------------------------------------------------------------------------------------------------------------

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?


select top 1 product_name ,(count(order_date)) as times_ordered from sales s join menu m on s.product_id =m.product_id group by product_name order by times_ordered desc 

-- 5. Which item was the most popular for each customer?

with popular_item_cte as (
select  product_name ,customer_id,(count(order_date)) as times_ordered ,
ROW_NUMBER() over ( partition by customer_id order by count(order_date) desc  ) as row,
RANK() over (partition by customer_id order by count(order_date) desc ) as rank 

from sales s join menu m on s.product_id =m.product_id  group by product_name ,customer_id  ) 

select customer_id, product_name , times_ordered from popular_item_cte where row =1  

--Point to Remeber (use row in case you want only one specific answer and rank for multiple answer )

------------------------------------------------------------------------------------------------------------------------------------------------------
-- 6. Which item was purchased first by the customer after they became a member?

with cte as (select  product_name ,me.customer_id ,order_date, join_date,
ROW_NUMBER() over (partition by me.customer_id order by order_date asc) as rn ,
RANK() over (partition by me.customer_id order by order_date asc) as rank
from sales s join menu m on s.product_id=m.product_id join members me on me.customer_id=s.customer_id where order_date>=join_date )

select product_name, customer_id from cte where rank =1
------------------------------------------------------------------------------------------------------------------------------------------------------


-- 7. Which item was purchased just before the customer became a member?

with cte as (select  product_name ,me.customer_id ,order_date, join_date,
ROW_NUMBER() over (partition by me.customer_id order by order_date desc) as rn ,
RANK() over (partition by me.customer_id order by order_date desc) as rank
from sales s join menu m on s.product_id=m.product_id join members me on me.customer_id=s.customer_id where order_date < join_date )

--select product_name,customer_id from cte where rank =1 and rn =1
------------------------------------------------------------------------------------------------------------------------------------------------------

-- 8. What is the total items and amount spent for each member before they became a member?

select sum(price) as amount_spent,count(product_name) as total_items, s.customer_id from sales s join menu m on s.product_id=m.product_id join members me on me.customer_id=s.customer_id where order_date < join_date group by s.customer_id

----Now to include the data for c who never joined as a member but bought product in diner anywas we use left join for sales and coalsce function for date to replace the null joining date to a far far date which will be true in else condition
select sum(price) as amount_spent,count(product_name) as total_items, s.customer_id from sales s join menu m on s.product_id=m.product_id left join members me on me.customer_id=s.customer_id where order_date <coalesce(join_date,'9999-12-31') group by s.customer_id


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select s.customer_id, sum(case when m.product_name='sushi' then m.price*20 else m.price*10 end) as points from sales s join menu m on s.product_id=m.product_id group by s.customer_id;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


select s.customer_id,
sum(case when s.order_date between me.join_date and DATEADD(DAY,6,me.join_date) then m.price*20 when m.product_name ='sushi' and s.order_date<me.join_date then m.price*20 else m.price*10 end) as points
from sales s join menu m on s.product_id=m.product_id join members me on s.customer_id=me.customer_id
WHERE DATEADD(month, DATEDIFF(month, 0, s.order_date), 0) = '2021-01-01'
 group by s.customer_id 



