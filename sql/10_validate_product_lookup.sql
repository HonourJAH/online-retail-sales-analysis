-- 10_validate_product_lookup.sql
-- Purpose: check that product_lookup has exactly one row per StockCode and that joining it
--          to the clean table does not change the row count (531,201).
-- Reads:   product_lookup, online_retail_clean


-- Check 1: one row per StockCode, and every product code in the clean table has a name.
-- Expected: all three numbers equal (3,811).
SELECT
    (SELECT COUNT(*) FROM product_lookup)                       AS lookup_rows,
    (SELECT COUNT(DISTINCT StockCode) FROM product_lookup)      AS distinct_codes_in_lookup,
    (SELECT COUNT(DISTINCT StockCode) FROM online_retail_clean) AS distinct_codes_in_clean;


-- Check 2: joining the lookup must not duplicate or drop sales rows.
-- Expected: 531,201.
SELECT COUNT(*) AS rows_after_join
FROM online_retail_clean AS clean_sales
JOIN product_lookup
    ON clean_sales.StockCode = product_lookup.StockCode;