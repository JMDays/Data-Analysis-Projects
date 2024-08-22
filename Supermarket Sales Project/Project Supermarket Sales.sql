SELECT TOP (1000) [Invoice_ID]
      ,[Branch]
      ,[City]
      ,[Customer_type]
      ,[Gender]
      ,[Product_line]
      ,[Unit_price]
      ,[Quantity]
      ,[Tax_5%]
      ,[Total]
      ,[Date]
      ,[Time]
      ,[Payment]
      ,[cogs]
      ,[gross_margin_%]
      ,[gross_income]
      ,[Rating]
  FROM [Supermarket_sales].[dbo].[Supermarket_Sales]

ALTER TABLE supermarket_sales
ALTER COLUMN gross_income FLOAT

ALTER TABLE supermarket_sales
ALTER COLUMN quantity int

ALTER TABLE supermarket_sales
ALTER COLUMN unit_price float

ALTER TABLE supermarket_sales
ALTER COLUMN total float

ALTER TABLE supermarket_sales
ALTER COLUMN cogs float

  -- Performance analysis by City and Branch
  Select distinct Branch from Supermarket_sales
  Select distinct City from Supermarket_sales

  Select city, branch, sum(gross_income) Total_income,
  round(sum(gross_income)/ (select sum(gross_income) from Supermarket_sales),2) Proportion
  from Supermarket_sales
  group by city, branch
  order by 3 desc

  /* 
Each one of the 3 branches is located in one of 3 different cities.
Naypyitaw Branch on City C is the branch that has the highest contribution to the overall income at 34%. 
This suggests that it is a top-performing branch. 
The location migh be contributing, but other factors but be analyzes such as customer demographics, or marketing strategies, in order to replicate
this success in other branches
Both Yangon Branch on City A and Mandalay Branch on City B contribute equally to the overall income (33% each). 
However, the company should determine if they are operating at their full potential or if there are opportunities to increase their contribution.
*/

  -- Performance Behaviour by type of Client
     -- QUantity bought per type of Client
  Select customer_type, sum(quantity) Total_QT_Bought, 
 cast(sum(quantity) * 1.0 / (select sum(quantity) from Supermarket_sales) as decimal (10,2))  Proportion
  from Supermarket_sales
  group by customer_type
  order by 3 desc

  Select customer_type, round(avg(unit_price),2) Avg_UnitPrice_bought
  from Supermarket_sales
  group by customer_type
  
  Select customer_type, sum(gross_income) Total_Income, 
  round(sum (gross_income)/ (select sum(gross_income ) from Supermarket_sales),2) Proportion
  from Supermarket_sales
  group by customer_type
  order by 3 desc

  /*	Data shows that members and normal customers contribute almost equally to quantity and total income (51% to Members vs 49% to Normal Clients in both variables), 
		although members tend to spend around 10$ more per unit.	
		The Company should enhance member loyalty and convert more normal customers into members to boost revenue.
	*/

-- Preferences by Gender

Select gender, product_line, sum(quantity) Units_bought
from Supermarket_sales
group by gender, product_line
order by 2, 3 desc

Select gender, product_line, sum(gross_income) Income
from Supermarket_sales
group by gender, product_line
order by 2, 3 desc

/*
Women bought more units in fashion and lifestyle products, 
but men generated slightly more revenue in electronic accessories, suggesting higher spending in tech categories.

In food and beverages, women bought more, but men generated less revenue, 
implying women may choose higher-value items.
*/

-- PREFERED PAYMENT METHOD

Select city, payment, count(invoice_id) no_of_payments
from supermarket_sales
group by city, payment
order by 1, 3 desc

Select payment, round(avg(gross_income),2) Avg_Invoice_value
from supermarket_sales
group by payment
order by 2 desc

/* Cash is the most frequently used payment method across all cities, 
yet it has the lowest average invoice value, suggesting it might be preferred for smaller transactions.

Despite Ewallets being the least used overall, 
they generate a higher average invoice value compared to credit cards, indicating they might be favored for larger purchases.

*/

-- PURCHASES PER SHIFT

with shifts as(
Select invoice_id, time, case 
when time between '10:00' and '13:00' then '1st Shift'
when time between '13:01' and '17:00' then '2nd Shift'
when time between '17:01' and '21:00' then '3rd Shift'
else 'yey'
end Shift_
from supermarket_sales)

Select BRANCH, Shift_, count(supermarket_sales.invoice_id) No_of_purchases
from supermarket_sales
join shifts on shifts.Invoice_ID=Supermarket_sales.Invoice_ID
group by BRANCH,Shift_
order by 1, 3 DESC

/*
Branch B has the most purchases (131) in the 3rd Shift, indicating strong late-hour sales.
Branch A peaks in the 2nd Shift, showing high mid-day activity.
Branch C has consistent purchases across all shifts, indicating balanced engagement.
This data could guide staffing and resource allocation, optimizing operations during peak shifts.
*/
