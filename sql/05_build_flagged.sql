-- 05_build_flagged.sql
-- Purpose: label every row with the reason it should be excluded (NULL = keep).
--          No rows are removed here, so every exclusion can be counted and audited.
-- Reads:   online_retail_stg
-- Builds:  online_retail_flagged (same row count as staging: 541,910)
-- Reasons are applied in priority order, so each excluded row gets exactly one:
--   1. non_product_code       postage, fees, manual entries, vouchers, etc.
--   2. matched_reversal_pair  two same-day order and cancellation pairs
--   3. zero_price             internal adjustments and unpriced lines
--   4. exact_duplicate        extra copies of rows identical on all 8 columns

DROP TABLE IF EXISTS online_retail_flagged;

CREATE TABLE online_retail_flagged AS
SELECT
    numbered_rows.*,
    CASE
        WHEN StockCode IN ('POST','DOT','M','C2','D','S','BANK CHARGES',
                           'AMAZONFEE','CRUK','B','PADS')
             OR StockCode LIKE 'gift\_%'
            THEN 'non_product_code'
        WHEN StockCode IN ('23166','23843')
             AND CustomerID IN (12346, 16446)
             AND ABS(Quantity) IN (74215, 80995)
            THEN 'matched_reversal_pair'
        WHEN Price = 0
            THEN 'zero_price'
        WHEN duplicate_copy_number > 1
            THEN 'exact_duplicate'
        ELSE NULL
    END AS exclusion_reason
FROM (
    SELECT
        Invoice, StockCode, Description, Quantity, InvoiceDate,
        Price, CustomerID, Country,
        ROW_NUMBER() OVER (
            PARTITION BY Invoice, StockCode, Description, Quantity,
                         InvoiceDate, Price, CustomerID, Country
        ) AS duplicate_copy_number
    FROM online_retail_stg
) AS numbered_rows;