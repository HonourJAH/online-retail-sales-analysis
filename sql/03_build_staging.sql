-- 03_build_staging.sql
-- Purpose: convert raw text columns to proper data types. No rows are removed.
-- Reads:   online_retail_raw
-- Builds:  online_retail_stg (same row count as raw: 541,910)
-- Notes:   Price is DECIMAL(10,3) because four raw prices have 3 decimals.
--          Blank descriptions and blank Customer IDs become NULL.

DROP TABLE IF EXISTS online_retail_stg;

CREATE TABLE online_retail_stg AS
SELECT
    Invoice,
    StockCode,
    NULLIF(TRIM(`Description`), '')                    AS Description,
    CAST(Quantity AS SIGNED)                           AS Quantity,
    STR_TO_DATE(InvoiceDate, '%m/%d/%y %H:%i')         AS InvoiceDate,
    CAST(Price AS DECIMAL(10,3))                       AS Price,
    CAST(NULLIF(TRIM(`Customer ID`), '') AS UNSIGNED)  AS CustomerID,
    Country
FROM online_retail_raw;