SELECT TOP (1000) [ORDERNUMBER]
      ,[QUANTITYORDERED]
      ,[PRICEEACH]
      ,[ORDERLINENUMBER]
      ,[SALES]
      ,[ORDERDATE]
      ,[STATUS]
      ,[QTR_ID]
      ,[MONTH_ID]
      ,[YEAR_ID]
      ,[PRODUCTLINE]
      ,[MSRP]
      ,[PRODUCTCODE]
      ,[CUSTOMERNAME]
      ,[PHONE]
      ,[ADDRESSLINE1]
      ,[ADDRESSLINE2]
      ,[CITY]
      ,[STATE]
      ,[POSTALCODE]
      ,[COUNTRY]
      ,[TERRITORY]
      ,[CONTACTLASTNAME]
      ,[CONTACTFIRSTNAME]
      ,[DEALSIZE]
  FROM [Project_Sales].[dbo].[SalesData]

--CHAPTER I - DATA CLEANING

-- MAin errors in Dataset start in column "Customer Name"

--1) Correcting column "customername"

Select customername, phone, addressline1, addressline2, city, state
from SalesData

Update SalesData
Set customername = case		
		when customername like '%"%' and phone like '%"%' then concat (customername, phone)
		else customername
		end

--2) Correcting column "phone"

Update SalesData
set phone = case when phone = right(customername, len(phone)) then ' '
else phone
end

Update SalesData
set phone = case when PATINDEX('%[A-Za-z]%', addressline1) = 0 and addressline1 not like '%"%' then addressline1
else phone
end

--3) Creating column "addressline1_"
Alter Table SalesData
Add addressline1_ nvarchar(250)

Update  SalesData
Set addressline1_ = case 
		when  addressline1 like '%"%' and addressline2 like '%"%' then concat(addressline1, addressline2)
		when PATINDEX('%[A-Za-z]%', addressline1) = 0 then addressline2
		else addressline1
		end

Update SalesData
Set ADDRESSLINE1 = addressline1_

Alter table SAlesdata
Drop column addressline1_

--4) Correcting column "addressline2"
Update SalesData
Set addressline2 =  case 
		when  right(ADDRESSLINE1, len(addressline2))= addressline2 then ' '
		else addressline2
		end

--5) Correcting column "City" and aplying last corrections to columns "addressline1_" and "addressline2"
Update  SalesData
Set ADDRESSLINE1 = case 
	when ADDRESSLINE1 like '%"%' and  city like '%"%' then concat (ADDRESSLINE1,addressline2, city)
	else ADDRESSLINE1
	end

Update SalesData
Set addressline2 =  case 
		when  right(ADDRESSLINE1, len(addressline2)) = addressline2 then ' '
		else addressline2
		end

Update Salesdata
Set addressline2 =  case 
		when PATINDEX('%[0-9]%', city) > 0 and city not like '%"%' then city
		else addressline2
		end

Update Salesdata
Set city =  case
		when city like '%"%' then postalcode --yes
		when city = ADDRESSLINE2 then state
		when city = ' ' then state
		else city
		end

--6) Correcting "State", 'Postal Code', 'Country' and "Territory" Column
Update Salesdata
Set state = case 
			when state = city then postalcode else state
			end

Update Salesdata
Set state = case
			when city = postalcode then postalcode else state
			end
			

Update Salesdata
Set postalcode = case 
		WHEN PATINDEX('%[0-9]%', TERRITORY) > 0 THEN TERRITORY
		WHEN PATINDEX('%[0-9]%', COUNTRY) > 0 THEN COUNTRy
		else postalcode
		end

Update SalesData
Set COUNTRY = case 
		when COUNTRY = POSTALCODE THEN TERRITORY
		WHEN COUNTRY = ' ' AND PATINDEX('%[0-9]%', TERRITORY) = 0 THEN TERRITORY
		WHEN COUNTRY = ' ' AND PATINDEX('%[0-9]%', TERRITORY) > 0 THEN CONTACTLASTNAME
		WHEN COUNTRY = 'OSAKA' THEN  'Japan'
		ELSE country
		END

Update SalesData
Set TERRITORY = case
WHEN TERRITORY = COUNTRY THEN CONTACTLASTNAME
		WHEN TERRITORY = POSTALCODE THEN CONTACTFIRSTNAME
		eLSE TERRITORY
		END

--7) Correcting "ContactLastname"

Update SalesData
Set Contactlastname = case
WHEN CONTACTLASTNAME= TERRITORY then CONTACTFIRSTNAME
when CONTACTLASTNAME= COUNTRY then SUBSTRING(dealsize, 1, charindex(',',dealsize)-1)
else CONTACTLASTNAME
end

Update SalesData
Set Contactlastname = case when
contactlastname = 'Japan' then  parsename(replace(dealsize, ',','.'),3)
else CONTACTLASTNAME
end

--8) Correcting "Firstname"

Update SalesData
Set contactfirstname = case
when contactfirstname = TERRITORY then parsename(replace(dealsize, ',','.'),2)
when contactfirstname = contactlastname then parsename(replace(dealsize, ',','.'),2)
when contactfirstname = 'Japan' then parsename(replace(dealsize, ',','.'),2)
else CONTACTFIRSTNAME
end 

--9) Correcting "Dealsize"
Update SalesData
Set dealsize = case 
when PATINDEX('%,%', dealsize) > 0 THEN parsename (replace(dealsize, ',','.'),1)
else dealsize
end

Select contactlastname, contactfirstname,  dealsize
from SalesData

ALTER TABLE SalesData
ALTER COLUMN Sales float


---



--------- Chapter II - ANALYSING BUSINESS RELEVANT INFO
-- 1)To identificate top 5 best-selling products

Select 
top 5 productcode, productline, sum(quantityordered ) as Total_orders
from salesdata
group by productcode, productline
order by 3 desc
/*
	Classic Cars and Trucks and Buses are the highest in quantity bought, with Classic Cars leading. 
	To leverage this, company should focus on enhancing the availability and marketing of Classic Cars to drive further sales. 
*/

--2) Who are the top 5 customers in terms of total purchase value ?

select top 5 CUSTOMERNAME, sum (sales) Total_purch_value
from salesdata
group by CUSTOMERNAME
order by 2 desc

--ANSWER: Euro Shopping Channel, Mini Gifts Distributors Ltd, "Australian Collectors Co.", Muscle Machine Inc and La Rochelle Gifts.

-- 3) Which month has the highest sales volume?
select MONTH_id, max(sales) SAles
from SalesData
group by MONTH_id
order by 2 desc

/* April has the highest sales, followed by November and May, indicating strong performance in spring and late fall. 
	However, sales dip in July, August, and December. 
	It would be advised to apply target marketing efforts to boost sales during these weaker months.
*/

--4) Which products had the top 10 higuest profit margin?

Select top 10 productcode, productline, max(priceeach - msrp) Profit_margin
from Salesdata
group by productcode, productline
order by 3 desc

/*
	These results indicate that Vintage Cars generally have higher profit margins compared to Classic Cars and Motorcycles. 
	Focusing on promoting and expanding the Vintage Cars line could enhance profitability.

*/

--5) Which countries had the best sales results?
with aux as 
(
Select YEAR_ID, country, max(sales) Sales,
rank ()over (partition by year_id order by sum(sales) desc) rankie
from salesdata
group by  year_id, COUNTRY
)

select YEAR_ID, country, Sales from aux
where rankie < 4

/* In all the years, USA Spain and France were the countries with a best Sales performance.
	Company should thereby tailor marketing approaches to reflect local preferences,
	develop partnerships with local influencers or businesses, 
	and use data analytics to identify and exploit specific opportunities in each market.

*/

--6) What was the distribution of order sizes in the 3 years ?

Select year_id, dealsize, count(ordernumber) No_Orders
from salesdata
group by year_id,dealsize
order by 1,2
-- 

/* The results show a decline in large deals from 2003 to 2005 and a peak in medium and small deals in 2004, followed by a sharp drop in 2005. 
	This suggests a loss of market share or declining customer interest. 
	The company should investigate the reasons for the decline, and enhance product offerings to better meet customer needs.
*/         

--7) Which quarter had the best sales performance?

with trim_ as 
(select ordernumber, month_ID , case 
	when MONTH_ID between 1 and 3 then 'Q1'
	when MONTH_ID between 4 and 6 then 'Q2'
	when MONTH_ID between 7 and 9 then 'Q3'
	when MONTH_ID between 10 and 12 then 'Q4'
	END QT_
	from salesdata)

Select YEAR_ID, QT_, sum(sales) Sales
from salesdata
join trim_ on trim_.ordernumber=salesdata.ordernumber
group by YEAR_ID,QT_
order by 3 desc

/* Data data shows Q4 as consistently the strongest quarter, with the peak in 2004. 
	However, there was a significant drop in Q4 sales from 2004 to 2005, suggesting a need to investigate and address potential issues. 
	While Q4 remains a key focus, efforts to boost performance in Q1 and Q2 could help stabilize sales throughout the year.
*/

-- 8) Identificate which productlines had the higues value in Sales durign 2005 in each territory.

with X as (
Select TERRITORY, productline, sum(sales) Total_sales,
rank ()over (partition by TERRITORY order by sum(sales) desc) rankie
from salesdata
where year_id = 2005
group by TERRITORY,productline
)

select TERRITORY, productline,Total_sales from X
where rankie < 4

/* Classic Cars led sales in both EMEA and NA, suggesting strong demand for this type of product in these regions. 
	Vintage Cars was the most popular in APAC.
	
	One recommendation would be to adjust inventory management and distribution strategies to ensure higher stock levels of "Classic Cars" in EMEA and NA regions 
	and more "Vintage Cars" in the APAC region. 
	This could involve reallocating production resources or optimizing supply chain operations to better match regional demand patterns.

	*/