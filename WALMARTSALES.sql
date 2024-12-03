create database  if not exists salesdatawalmart;

create table sales(
Invoice_id varchar(16) not null,
Branch varchar (4) not null,
City varchar(20) not null,
Customer_type varchar(10) not null,
Gender varchar(10) not null,
Product_line varchar(40) not null,
Unit_Price decimal(5,4) not null,
Quantity int not null,
VAT float(6,4) not null,
Total decimal(12,4) not null,
Date date not null,
time Time not null,
payment_method varchar(15) not null,
cogs decimal(10,2) not null,
gross_margine_pct float not null,
gross_income decimal(12,4) not null,
rating float not null);
alter table sales modify column unit_price float;
select * from sales;


-- ------------------------------------------------------ FEATURE ENGINEERING ------------------------------------------------------------------------ --


-- daytime --



select branch,time,(  
	case 
    when `time` between "00:00:00" and '12:00:00' then "Morning"
    when `time` between "12:00:00" and '16:00:00' then "Afternoon"
    else "Evening"
    end) as Time_of_day
    from sales;
    
SELECT branch, 
    CASE 
        WHEN TIME(`time`) >= "00:00:00" AND TIME(`time`) <= "12:00:00" THEN "Morning"
        WHEN TIME(`time`) > "12:00:00" AND TIME(`time`) <= "16:00:00" THEN "Afternoon"
        ELSE "Evening"
    END AS Time_of_day
FROM sales;

alter table sales add column time_of_day varchar(40);

update sales set time_of_day =  CASE 
        WHEN TIME(`time`) >= "00:00:00" AND TIME(`time`) <= "12:00:00" THEN "Morning"
        WHEN TIME(`time`) > "12:00:00" AND TIME(`time`) <= "16:00:00" THEN "Afternoon"
        ELSE "Evening"
    END;
    
--                 day name              --

alter table sales add column day_name varchar(20);

update sales set day_name = dayname(date);
select * from sales;

--                month name           --
alter table sales add column month_name varchar(20);

update sales set month_name = monthname(date);

--              ------------------------GENERIC QUESTION---------------------------- -- ---------------------------
-- HOW MANY UNIQUE CITIES DOES THE DATA HAVE?      --
SELECT DISTINCT city from sales;

-- IN WHICH CITY IS EACH BRANCH?                 --
 SELECT DISTINCT CITY, BRANCH  FROM SALES;   -- USE DISTINCT FUNCTION WITH ONLY ONE COLUMN OTHER WILL BE DISTINCTED ACCORDINGLY.   --  

-- HOW MANY UNIQUE PRODUCT LINES DOES THE DATA HAVE? --
select count(distinct product_line) from sales;

-- WHAT IS THE MOST COMMON PAYMENT METHOD --

SELECT COUNT(payment_method) AS COUNT , payment_method FROM SALES 
GROUP BY payment_method ORDER BY COUNT DESC LIMIT 1 ; 

-- WHAT IS THE MOST SELLING PRODUCT LINE?     --
select COUNT(PRODUCT_LINE) AS COUNT,PRODUCT_LINE FROM SALES GROUP BY PRODUCT_LINE order by count desc limit 1;

-- WHAT IS THE AVERAGE RATING OF EACH PRODUCT LINE --
 
 SELECT AVG(RATING) ,PRODUCT_LINE FROM SALES GROUP BY PRODUCT_LINE ORDER BY AVG(RATING) DESC;

-- WHICH TIME OF THE DAY DO CUSTOMERS GIVE MOST RATINGS --

 SELECT COUNT(RATING) count,time_of_day FROM sales group by time_of_day order by count desc limit 1 ;

-- WHICH TIME OF THE DAY DO CUSTOMERS GIVE MOST RATINGS PER BRANCH --

select max(count) , time_of_day ,Branch
from (
SELECT COUNT(RATING) count,time_of_day, branch 
FROM sales group by time_of_day,branch 
order by branch) as q group by time_of_day,branch;
 ;

--   Which time of the day do customers give most ratings per branch? --


SELECT AVG(RATING) AS AVGG, day_name , BRANCH FROM SALES 
group by day_name , BRANCH
ORDER BY BRANCH,AVGG DESC ;


WITH AvgTable AS (
    SELECT 
        BRANCH, 
        time_of_day, 
        AVG(rating) AS AVGG 
    FROM sales
    GROUP BY BRANCH, time_of_day
),
MaxValues AS (
    SELECT 
        BRANCH, 
        MAX(AVGG) AS max_avgg
    FROM AvgTable
    GROUP BY BRANCH
)
SELECT at.BRANCH, at.time_of_day, at.AVGG
FROM AvgTable at
JOIN MaxValues mv
ON at.BRANCH = mv.BRANCH AND at.AVGG = mv.max_avgg;


with avgtable as (
	select avg(rating) as avgg , time_of_day , branch
    from sales group by time_of_day,branch order by branch desc),
maxavg as (
	select max(avgg) as maxxx ,branch from avgtable group by branch)
select a.avgg , a.time_of_day , a.branch from avgtable a 
join maxavg m on a.avgg = m.maxxx;

-- WHICH DAY OF THE WEEK HAS THE BEST AVG RATING --
SELECT AVG(RATING) AS AVGG, day_name FROM SALES group by day_name 
ORDER BY AVGG DESC LIMIT 1;

   -- Which day of the week has the best average ratings per branch ---

with avgrat as 
(select avg(rating) as avgg, day_name , branch from sales 
group by day_name , branch order by branch),
maxavg as ( select max(avgg) maxx , branch from avgrat group by branch)
select a.avgg , a.day_name , a.branch from avgrat a
join maxavg m on a.avgg = m.maxx;

--    Which city has the largest tax percent/ VAT (**Value Added Tax**)?     --

select max(cogs*0.5)as maxmtax, city from sales group by city order by maxmtax desc limit 1;
 
-- What is the gender of most of the customers? --

select count(gender) , gender from sales group by gender;

--    What is the gender distribution per branch?     --

select count(gender),gender,branch from sales group by gender,Branch order by Branch;

  --  Number of sales made in each time of the day per weekday  --

select count(Invoice_id) as Sales_Count , day_name,time_of_day from sales
group by day_name,time_of_day 
order by FIELD(day_name, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');

--     What is the most common customer type?    --

select count(Customer_type) as count , customer_type 
from sales group by Customer_type order by count desc limit 1;

   --    Which customer type buys the most?    --

select sum(total) as totalrevenue , Customer_type from sales
group by Customer_type order by totalrevenue desc limit 1;


--    Which branch sold more products than average product sold?    --

select avg(Quantity) as avgunits , branch from sales 
group by branch having avgunits > (select avg(Quantity) from sales);

--    What is the most common product line by gender      --

SELECT count(Product_line) as count , gender 
from sales group by gender order by count desc limit 1;

--  Fetch each product line and add a column to those product line showing "Good", "Bad". Good if its greater than average sales  --

with avgsales as (select avg(Quantity) as avg_quantity,product_line from sales group by Product_line)
select avg_quantity , product_line , case
when  avg_quantity > (select avg(Quantity) from sales) then 'Good'
else 'Bad' 
end as sales_stats
 from avgsales;
 
 --                What is the most common payment method?          --
 
 select count(payment_method) , payment_method from sales
 group by payment_method order by payment_method desc limit 1;
 
 --              What is the total revenue by month?            --
 
 select round(sum(total),2) as total_revenue , month_name from sales 
 group by month_name;
 
 --          What month has the largest cogs?                --
 
 select sum(cogs) cogsrevenue , month_name from sales
 group by month_name order by cogsrevenue desc limit 1;
 
 --              What product line had the largest revenue            --
 
 select round(sum(total),2) as revenue , product_line from sales
 group by Product_line order by revenue desc limit 1;
 
 --    What is the city with the largest revenue?  --
 
  select round(sum(total),2) as revenue , city from sales
 group by city order by revenue desc limit 1;
 
 --       What product line had the largest VAT?             --
 
 select round(sum(vat),2) as total_vat , product_line from sales
 group by Product_line order by total_vat desc limit 1;
 
 --     Which of the customer types brings the most revenue?    -- 
 
   select round(sum(total),2) as revenue , Customer_type from sales
 group by Customer_type order by revenue desc limit 1;
 
--       Which customer type pays the most in VAT?            --
 
 select round(sum(vat),2) as total_vat , Customer_type from sales
 group by Customer_type order by total_vat desc limit 1;
 
 
 
 
-- ------------------------------------------ PRODUCT ----------------------------------- --

--          1. How many unique product lines does the data have?            --
SELECT DISTINCT(PRODUCT_LINE) FROM SALES;

--          2. What is the most common payment method?                      --
SELECT COUNT(payment_method) as count, payment_method from sales
group by payment_method order by count desc limit 1;

--          3. What is the most selling product line?                       --

SELECT COUNT(Product_line) as count, Product_line from sales
group by Product_line order by count desc limit 1;

--          4. What is the total revenue by month?                          --

 select round(sum(total),2) as total_revenue , month_name from sales 
 group by month_name;






