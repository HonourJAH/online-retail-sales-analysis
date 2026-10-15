-- 07_build_clean.sql
-- Purpose: build the analysis table from the rows that were not excluded.
-- Reads:   online_retail_flagged
-- Builds:  online_retail_clean (531,201 rows)
-- Adds:    is_cancellation (1 if the invoice starts with C, otherwise 0)
--          line_total      (Quantity * Price; negative for cancellations)
-- Also:    standardizes three country names. Values are not rounded here.

DROP TABLE IF EXISTS online_retail_clean;

CREATE TABLE online_retail_clean AS
SELECT
    Invoice,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    Price,
    CustomerID,
    CASE Country
        WHEN 'EIRE' THEN 'Ireland'
        WHEN 'RSA'  THEN 'South Africa'
        WHEN 'USA'  THEN 'United States'
        ELSE Country
    END                     AS Country,
    (Invoice LIKE 'C%')     AS is_cancellation,
    Quantity * Price        AS line_total
FROM online_retail_flagged
WHERE exclusion_reason IS NULL;