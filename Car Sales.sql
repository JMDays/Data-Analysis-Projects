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
		when  right(addressline1_, len(addressline2))= addressline2 then ' '
		else addressline2
		end

--5) Correcting column "City" and aplying last corrections to columns "addressline1_" and "addressline2"
Update  SalesData
Set addressline1_ = case 
	when addressline1_ like '%"%' and  city like '%"%' then concat (addressline1_,addressline2, city)
	else addressline1_
	end

Update SalesData
Set addressline2 =  case 
		when  right(addressline1_, len(addressline2)) = addressline2 then ' '
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

---
Select * from SalesData

--------- Chapter II - ANALYSING BUSINESS RELEVANT INFO
-- 1)To identificate top 5 best-selling products

Select 
top 5 productcode, productline, sum(quantityordered ) as Total_orders
from salesdata
group by productcode, productline
order by 3 desc


--2) Who are the top 5 customers in terms of total purchase value ?

select top 5 CUSTOMERNAME, sum (cast(sales as float)) Total_purch_value
from salesdata
group by CUSTOMERNAME
order by 2 desc
--ANSWER: Euro Shopping Channel, Mini Gifts Distributors Ltd, "Australian Collectors Co.", Muscle Machine Inc and La Rochelle Gifts.

select * from SalesData
-- 3) Which month has the highest sales volume?
select MONTH_id, max(sales)
from SalesData
group by MONTH_id
order by 2 desc
--ANSWER: May


--4) Which product has the highest profit margin?

Select productcode, productline, max(priceeach - msrp)
from Salesdata
group by productcode, productline
order by 3 desc

--Answer: Product S24_1937 (Vintage Cars)


-- 5) Which city has the highest number of orders?

Select city, country, count(ordernumber)
from Salesdata
group by city, COUNTRY
order by 3 desc

--Answer: Madrid

--6) What is the distribution of order sizes ?

Select dealsize, count(ordernumber), (count(ordernumber)*1.0) / (select count(*) from salesdata) as proportion
from salesdata
group by dealsize
-- Answer: Large -> 0,06% ; Medium -> 49,02 %, Small -> 45,41%.
           

--7) What are the top 3 states in terms of total sales value?

select top 3 state, sum(cast(sales as float))
from salesdata
group by state
order by 1 desc

-- Answer: Victoria, Tokyo and Singapore.

--8) Which quarter has the best sales performance?

with trim_ as 
(select ordernumber, month_ID , case 
	when MONTH_ID between 1 and 3 then 'Q1'
	when MONTH_ID between 4 and 6 then 'Q2'
	when MONTH_ID between 7 and 9 then 'Q3'
	when MONTH_ID between 10 and 12 then 'Q4'
	END QT_
	from salesdata)

Select YEAR_ID, QT_, sum(cast(sales as float)) Sales
from salesdata
join trim_ on trim_.ordernumber=salesdata.ordernumber
group by YEAR_ID,QT_
order by 3 desc

--Answer: The best sales performance was achieved in Q4 from 2004.


--9) What is the trend in sales over the years?

Select year_id, sum(cast(sales as float))
from salesdata
group by year_id
order by 2 desc

-- There was an increase of total sales from 2023 to 2024, but the value decreased in 2005, achieving a lower value than 2003.


-- 10) Identificate which productlines had the higues value in Sales durign 2005 in each territory.

with X as (
Select TERRITORY, productline, sum(cast(sales as float)) Total_sales,
rank ()over (partition by TERRITORY order by sum(cast(sales as float)) desc) rankie
from salesdata
where year_id = 2005
group by TERRITORY,productline
)

select TERRITORY, productline,Total_sales from X
where rankie < 4

-- The productline "Classic Cars" had the greatest value of Sales in EMEA and USA. IN APAC, it was 'Vintage Cars".
