-- 02_profile_raw.sql
-- Purpose: measure completeness, validity and consistency of the raw table before any cleaning.
--          Covers row count, blank values, price decimal places, and non-numeric values
--          in Customer ID, Quantity and Price.
-- Reads:   online_retail_raw

SELECT COUNT(*) AS total_rows
FROM online_retail_raw;


SELECT *
FROM online_retail_raw
LIMIT 10;


SELECT
    COUNT(*)                          AS total_rows,
    SUM(Invoice = '')                 AS blank_invoice,
    SUM(StockCode = '')               AS blank_stockcode,
    SUM(`Description` = '')           AS blank_description,
    SUM(Quantity = '')                AS blank_quantity,
    SUM(InvoiceDate = '')             AS blank_invoicedate,
    SUM(Price = '')                   AS blank_price,
    SUM(`Customer ID` = '')           AS blank_customer_id,
    ROUND(100 * SUM(`Customer ID` = '') / COUNT(*), 1) AS pct_blank_customer,
    SUM(Country = '')                 AS blank_country
FROM online_retail_raw;


-- checking for Prices' decimals and their counts
SELECT
    LENGTH(SUBSTRING_INDEX(Price, '.', -1)) AS decimal_places,
    COUNT(*) AS n
FROM online_retail_raw
WHERE Price LIKE '%.%'
GROUP BY decimal_places
ORDER BY decimal_places;


-- look at those 4 rows that have prices with 3 decimals
SELECT *
FROM online_retail_raw
WHERE Price LIKE '%.%'
AND LENGTH(SUBSTRING_INDEX(Price, '.', -1)) = 3;


-- count the true zero-price rows in raw
SELECT COUNT(*) AS zero_price_rows
FROM online_retail_raw
WHERE CAST(Price AS DECIMAL(10,3)) = 0;


-- find any Customer ID that isn’t a plain whole number
SELECT `Customer ID`, COUNT(*) AS n
FROM online_retail_raw
WHERE `Customer ID` <> ''
  AND `Customer ID` NOT REGEXP '^[0-9]+$'
GROUP BY `Customer ID`;


-- find any Quantity that isn’t a whole number
SELECT Quantity, COUNT(*) AS n
FROM online_retail_raw
WHERE Quantity NOT REGEXP '^-?[0-9]+$'
GROUP BY Quantity;


-- find any Price that isn’t a plain number
SELECT Price, COUNT(*) AS n
FROM online_retail_raw
WHERE Price NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
GROUP BY Price;





