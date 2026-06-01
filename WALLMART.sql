-- Walmart Project Queries - MySQL

SELECT * FROM walmart;

-- Count total records
SELECT COUNT(*) FROM walmart;

-- Count payment methods and number of transactions by payment method
SELECT distinct payment_method FROM walmart;

select 
  payment_method, 
  count(*) as count 
  from walmart
  group by payment_method
  order by count desc;

-- Count distinct branches
select count(distinct branch) from walmart;

-- Find the minimum quantity sold
select min(quantity) from walmart;
select max(quantity) from walmart;

-- Business Problem Q1: Find different payment methods, number of transactions, and quantity sold by payment method
select 
   payment_method,
   count(*) as number_of_payments,
   sum(quantity) as no_of_quantity_sold
FROM walmart
group by payment_method;   

-- Project Question #2: Identify the highest-rated category in each branch
-- Display the branch, category, and avg rating

with cte as (
SELECT 
     branch,
     category,
     avg(rating) AS avg_rating,
     dense_rank() over (partition by branch order by avg(total) desc) as rnk
FROM walmart
group by branch, category)

select * from cte
where rnk=1;

-- Q3: Identify the busiest day for each branch based on the number of transactions

with cte as (
select
      branch, 
      dayname(str_to_date(date,'%d/%m/%y')) as day_name,
      count(*) as no_transaction,
      rank() over(partition by branch order by count(*) desc) as rnk
      
 from walmart
 group by branch, day_name)
 
 select * from cte 
 where rnk=1;
 
 
 -- Q4: Calculate the total quantity of items sold per payment method

SELECT 
    payment_method,
    sum(quantity) as no_qty_sold
 FROM walmart
 group by payment_method
 order by no_qty_sold desc;

-- Q5: Determine the average, minimum, and maximum rating of categories for each city

SELECT 
     city,
     category,
     min(rating) AS min_rating,
     max(rating) AS max_rating,
     avg(rating) AS avg_rating
from walmart
group by city, category ;

-- Q6: Calculate the total profit for each category

SELECT
     category,
     round(sum(total),2) AS total_revenue,     
     round(sum(total*profit_margin),2) AS Profit
 FROM walmart
 group by category
 order by Profit desc;
    
-- Q7: Determine the most common payment method for each branch

with cte as (
SELECT
     branch,
     payment_method,
     count(*) AS total_txn,
     rank() over(partition by branch order by count(*) desc) as rnk
 FROM walmart
 group by branch, payment_method)
 
 select * from cte 
 where rnk= 1;

-- Q8: Categorize sales into Morning, Afternoon, and Evening shifts

select 
	
      case 
        when hour(time) < 12 then 'Morning'
        when hour(time) between 12 and 17 then 'Afternoon'
        else 'Evening'      
    
       end AS shift,
    count(*) AS number_of_txn
    
from walmart
group by  shift
order by  number_of_txn desc;

-- Q9: Identify the 5 branches with the highest revenue decrease ratio from last year to current year (e.g., 2022 to 2023)


with cte1 as (
select
   branch,
   sum(total) as revenue
FROM walmart
WHERE  year(str_to_date(date, '%d/%m/%y')) = 2022
group by branch),

 cte2 as (
select
   branch,
   sum(total) as revenue
FROM walmart
WHERE  year(str_to_date(date, '%d/%m/%y')) = 2023
group by branch)

select 
      branch,
      c1.revenue as rev_2022,
      c2.revenue as rev_2023,
      round(((c1.revenue-c2.revenue)/c1.revenue*100),2) as rev_dec_ratio
      
FROM cte1 c1
JOIN cte2 c2   
USING (branch) 
WHERE   c1.revenue >  c2.revenue
ORDER BY rev_dec_ratio DESC
LIMIT 5;
     
   
