-- 04_profile_staging.sql
-- Purpose: profile the typed staging table to find the issues that need a cleaning decision.
--          Covers date range, quantity and price validity, cancellations, internal adjustments,
--          non-product StockCodes, exact duplicates, multiple descriptions per StockCode,
--          extreme quantities, same-day reversals and country values.
-- Reads:   online_retail_stg


 -- confirm no rows were lost or added
SELECT COUNT(*) AS stg_rows
FROM online_retail_stg;


-- check for failed dates and see the range
SELECT
    COUNT(*) - COUNT(InvoiceDate) AS null_dates,
    MIN(InvoiceDate)              AS first_invoice,
    MAX(InvoiceDate)              AS last_invoice
FROM online_retail_stg;


-- QUANTITY PROFILING
SELECT
    SUM(Quantity < 0)  AS negative_qty,
    SUM(Quantity = 0)  AS zero_qty,
    SUM(Quantity > 0)  AS positive_qty,
    MIN(Quantity)      AS min_qty,
    MAX(Quantity)      AS max_qty
FROM online_retail_stg;


-- break down the negative quantities
SELECT
    CASE
        WHEN Invoice LIKE 'C%' THEN 'C (cancellation)'
        WHEN Invoice LIKE 'A%' THEN 'A (adjustment)'
        ELSE 'other (no prefix)'
    END                          AS invoice_type,
    COUNT(*)                     AS n_rows,
    SUM(Price = 0)               AS zero_price,
    SUM(CustomerID IS NULL)      AS no_customer
FROM online_retail_stg
WHERE Quantity < 0
GROUP BY invoice_type;


-- check how many of the 1,336 have a description
SELECT
    SUM(Description IS NULL)     AS null_description,
    SUM(Description IS NOT NULL) AS has_description
FROM online_retail_stg
WHERE Quantity < 0
  AND Invoice NOT LIKE 'C%'
  AND Invoice NOT LIKE 'A%';
  
  
  -- see the descriptions on the 474 rows
  SELECT Description, COUNT(*) AS n
FROM online_retail_stg
WHERE Quantity < 0
  AND Invoice NOT LIKE 'C%'
  AND Invoice NOT LIKE 'A%'
  AND Description IS NOT NULL
GROUP BY Description
ORDER BY n DESC
LIMIT 20;
  

-- PRICE PROFILING

SELECT
    SUM(Price < 0)                    AS negative_price,
    SUM(Price = 0)                    AS zero_price,
    SUM(Price = 0 AND Quantity > 0)   AS zero_price_positive_qty,
    SUM(Price > 0)                    AS positive_price,
    MIN(Price)                        AS min_price,
    MAX(Price)                        AS max_price
FROM online_retail_stg;


-- profile the 1,179 zero-price positive-quantity rows
SELECT
    SUM(CustomerID IS NULL)      AS no_customer,
    SUM(CustomerID IS NOT NULL)  AS has_customer,
    SUM(Description IS NULL)     AS null_description,
    SUM(Description IS NOT NULL)  AS has_description
FROM online_retail_stg
WHERE Price = 0
  AND Quantity > 0;


-- see the descriptions on the zero-price positive-quantity rows
SELECT Description, COUNT(*) AS n
FROM online_retail_stg
WHERE Price = 0
  AND Quantity > 0
  AND Description IS NOT NULL
GROUP BY Description
ORDER BY n DESC
LIMIT 20;


-- the 40 zero-price rows that have a customer
SELECT Invoice, StockCode, Description, Quantity, InvoiceDate, CustomerID, Country
FROM online_retail_stg
WHERE Price = 0
  AND Quantity > 0
  AND CustomerID IS NOT NULL
ORDER BY InvoiceDate;


-- the extreme prices
SELECT Invoice, StockCode, Description, Quantity, Price, CustomerID
FROM online_retail_stg
WHERE Price < 0 OR Price > 1000
ORDER BY Price DESC;


-- list every StockCode that doesn’t look like a product code
SELECT
    StockCode,
    MIN(Description) AS sample_description,
    COUNT(*)         AS n_rows
FROM online_retail_stg
WHERE StockCode NOT REGEXP '^[0-9]{5}'
GROUP BY StockCode
ORDER BY n_rows DESC;


-- check how many DCGS rows the earlier exclusions already cover
SELECT
    COUNT(*)                     AS dcgs_rows,
    SUM(Price = 0)               AS zero_price,
    SUM(CustomerID IS NULL)      AS no_customer,
    SUM(Description IS NULL)     AS null_description
FROM online_retail_stg
WHERE StockCode LIKE 'DCGS%';


-- count exact duplicates in staging
SELECT
    COUNT(*)       AS duplicated_groups,
    SUM(c - 1)     AS extra_rows
FROM (
    SELECT Invoice, StockCode, Description, Quantity,
           InvoiceDate, Price, CustomerID, Country,
           COUNT(*) AS c
    FROM online_retail_stg
    GROUP BY Invoice, StockCode, Description, Quantity,
             InvoiceDate, Price, CustomerID, Country
    HAVING COUNT(*) > 1
) AS d;


-- the 15 most-repeated rows
SELECT Invoice, StockCode, Description, Quantity, InvoiceDate,
       Price, CustomerID, COUNT(*) AS copies
FROM online_retail_stg
GROUP BY Invoice, StockCode, Description, Quantity, InvoiceDate,
         Price, CustomerID, Country
HAVING COUNT(*) > 1
ORDER BY copies DESC
LIMIT 15;


-- the value of the extra copies
WITH ranked AS (
    SELECT Quantity, Price,
           ROW_NUMBER() OVER (
               PARTITION BY Invoice, StockCode, Description, Quantity,
                            InvoiceDate, Price, CustomerID, Country
           ) AS rn
    FROM online_retail_stg
)
SELECT
    COUNT(*)                        AS extra_rows,
    ROUND(SUM(Quantity * Price), 2) AS extra_value
FROM ranked
WHERE rn > 1;

SELECT ROUND(SUM((c - 1) * Quantity * Price), 2) AS extra_value_check
FROM (
    SELECT Quantity, Price, COUNT(*) AS c
    FROM online_retail_stg
    GROUP BY Invoice, StockCode, Description, Quantity,
             InvoiceDate, Price, CustomerID, Country
    HAVING COUNT(*) > 1
) AS d;


-- gross product sales for scale
SELECT ROUND(SUM(Quantity * Price), 2) AS gross_product_sales
FROM online_retail_stg
WHERE Quantity > 0
  AND Price > 0
  AND StockCode REGEXP '^[0-9]{5}';


-- count product codes with more than one description
SELECT COUNT(*) AS stockcodes_with_multiple_desc
FROM (
    SELECT StockCode
    FROM online_retail_stg
    WHERE StockCode REGEXP '^[0-9]{5}'
      AND Description IS NOT NULL
    GROUP BY StockCode
    HAVING COUNT(DISTINCT Description) > 1
) AS t;


-- every description recorded for StockCode 23084
SELECT
    Description,
    COUNT(*)         AS n_rows,
    MIN(InvoiceDate) AS first_seen,
    MAX(InvoiceDate) AS last_seen
FROM online_retail_stg
WHERE StockCode = '23084'
GROUP BY Description
ORDER BY first_seen;


-- recounting the multi-description product codes, only on rows with a price above zero
SELECT COUNT(*) AS stockcodes_with_multiple_desc
FROM (
    SELECT StockCode
    FROM online_retail_stg
    WHERE StockCode REGEXP '^[0-9]{5}'
      AND Description IS NOT NULL
      AND Price > 0
    GROUP BY StockCode
    HAVING COUNT(DISTINCT Description) > 1
) AS t;


-- the competing descriptions for the worst cases
SELECT
    StockCode,
    COUNT(DISTINCT Description) AS n_desc,
    GROUP_CONCAT(DISTINCT Description ORDER BY Description SEPARATOR ' | ') AS descriptions
FROM online_retail_stg
WHERE StockCode REGEXP '^[0-9]{5}'
  AND Description IS NOT NULL
  AND Price > 0
GROUP BY StockCode
HAVING COUNT(DISTINCT Description) > 1
ORDER BY n_desc DESC
LIMIT 15;


-- every row for those two customers (12346, 16446) with same-day full reversals
SELECT Invoice, StockCode, Description, Quantity, InvoiceDate, Price, CustomerID
FROM online_retail_stg
WHERE CustomerID IN (12346, 16446)
ORDER BY CustomerID, InvoiceDate;


-- other extreme quantities
SELECT Invoice, StockCode, Description, Quantity, Price, CustomerID, InvoiceDate
FROM online_retail_stg
WHERE ABS(Quantity) >= 3000
ORDER BY ABS(Quantity) DESC;


-- find same-day, same-line reversals by value
SELECT
    o.CustomerID,
    o.StockCode,
    o.Quantity,
    o.Price,
    ROUND(o.Quantity * o.Price, 2) AS line_value,
    o.Invoice      AS original_invoice,
    c.Invoice      AS cancel_invoice
FROM online_retail_stg o
JOIN online_retail_stg c
  ON  c.CustomerID = o.CustomerID
  AND c.StockCode  = o.StockCode
  AND c.Quantity   = -o.Quantity
  AND c.Price      = o.Price
  AND DATE(c.InvoiceDate) = DATE(o.InvoiceDate)
  AND c.Invoice LIKE 'C%'
WHERE o.Invoice NOT LIKE 'C%'
  AND o.Quantity > 0
ORDER BY line_value DESC
LIMIT 15;


-- list of every country with its row count
SELECT Country, COUNT(*) AS n_rows
FROM online_retail_stg
GROUP BY Country
ORDER BY n_rows DESC;


-- what’s inside the Unspecified rows
SELECT
    COUNT(*)                      AS n_rows,
    SUM(CustomerID IS NULL)       AS no_customer,
    SUM(Price = 0)                AS zero_price,
    SUM(Quantity < 0)             AS negative_qty,
    ROUND(SUM(CASE WHEN Quantity > 0 AND Price > 0
                   THEN Quantity * Price END), 2) AS positive_sales
FROM online_retail_stg
WHERE Country = 'Unspecified';





