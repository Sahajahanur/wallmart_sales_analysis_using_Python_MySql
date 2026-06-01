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
     
-- Q10: Which branch and category combination generated the highest revenue each year?
     
     WITH cte AS (
    SELECT 
        branch,
        category,
        YEAR(STR_TO_DATE(date, '%d/%m/%Y')) AS yr,
        ROUND(SUM(total), 2)                AS revenue,
        RANK() OVER (
            PARTITION BY YEAR(STR_TO_DATE(date, '%d/%m/%Y')) 
            ORDER BY SUM(total) DESC
        ) AS rnk
    FROM walmart
    GROUP BY branch, category, yr
)
SELECT 
    yr,
    branch,
    category,
    revenue
FROM cte
WHERE rnk = 1
ORDER BY yr;
   
   
-- Q11: Which product categories generate the most revenue and have the highest quantity sold — ranked overall?   

SELECT 
    category,
    SUM(quantity)              AS total_qty_sold,
    ROUND(SUM(total), 2)       AS total_revenue,
    ROUND(AVG(rating), 2)      AS avg_rating,
    COUNT(*)                   AS total_transactions,
    RANK() OVER (
        ORDER BY SUM(total) DESC
    )                          AS revenue_rank
FROM walmart
GROUP BY category
ORDER BY revenue_rank;

-- Q12: Which shift (Morning/Afternoon/Evening) performs best in each city by revenue?

SELECT 
    city,
    CASE 
        WHEN HOUR(time) < 12 THEN 'Morning'
        WHEN HOUR(time) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END                      AS shift,
    payment_method,
    COUNT(*)                 AS total_transactions,
    ROUND(SUM(total), 2)     AS total_revenue,
    ROUND(AVG(rating), 2)    AS avg_rating
FROM walmart
GROUP BY city, shift, payment_method
ORDER BY city, total_revenue DESC;

-- Q13: What is the peak sales shift, day, and month — and how does customer spending vary across them?

SELECT 
    YEAR(STR_TO_DATE(date, '%d/%m/%Y'))         AS yr,
    MONTHNAME(STR_TO_DATE(date, '%d/%m/%Y'))     AS month_name,
    DAYNAME(STR_TO_DATE(date, '%d/%m/%Y'))       AS day_name,
    CASE 
        WHEN HOUR(time) < 12 THEN 'Morning'
        WHEN HOUR(time) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END                                          AS shift,
    COUNT(*)                                     AS total_transactions,
    ROUND(SUM(total), 2)                         AS total_revenue,
    ROUND(AVG(total), 2)                         AS avg_spend_per_txn,
    ROUND(AVG(quantity), 2)                      AS avg_qty_per_txn
FROM walmart
GROUP BY yr, month_name, day_name, shift
ORDER BY total_revenue DESC
LIMIT 10;


-- =============================================================
-- KEY FINDINGS & RECOMMENDATIONS — WALMART SALES ANALYSIS
-- =============================================================

-- CATEGORY PERFORMANCE
-- • Fashion Accessories & Home and Lifestyle are top revenue drivers
--   (~489K each) — nearly equal, neck-to-neck competition
-- • Food & Beverages has the highest avg rating (7.11) but lowest
--   transactions (174) — high satisfaction, low reach (hidden gem)
-- • Electronic Accessories ranks 3rd in revenue (78K) with decent
--   avg rating (5.91)

-- BRANCH & YEARLY TRENDS
-- • Home and Lifestyle dominated branch-level revenue in 2019, 2021, 2022
-- • Fashion Accessories took top spot in 2020 and 2023
-- • No single branch dominates consistently year over year
-- • WALM029 (2022) and WALM038 (2023) are most recent top performers

-- TIME & SHIFT PATTERNS
-- • Afternoon shift (12PM–5PM) dominates ALL top 10 peak periods
-- • Saturday + Afternoon = highest revenue combination overall
-- • 2019 March Saturday Afternoon = all-time peak (14425.61 revenue)
-- • January and March repeat frequently in peak periods —
--   seasonal buying surge is predictable and consistent

-- PAYMENT & CITY INSIGHTS
-- • Ewallet is the most preferred payment method across cities
-- • Evening + Ewallet combo is strongest in Abilene
-- • Cash transactions are minimal — digital payments dominate

-- RECOMMENDATIONS
-- • Invest heavily in Fashion Accessories & Home and Lifestyle inventory
-- • Aggressively promote Food & Beverages — untapped potential
-- • Deploy more staff during Afternoon shift, especially on Saturdays
-- • Plan advance stock for January and March seasonal surges
-- • Offer Ewallet loyalty rewards to retain dominant payment users
-- • Replicate WALM029 & WALM038 strategies in underperforming branches

-- =============================================================
