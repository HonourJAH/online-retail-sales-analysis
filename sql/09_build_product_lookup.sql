-- 09_build_product_lookup.sql
-- Purpose: one product name per StockCode, because some codes carry several descriptions.
-- Reads:   online_retail_clean
-- Builds:  product_lookup (3,811 rows, one per StockCode)
-- Rule:    the most frequently used description wins; the most recent use breaks ties.

DROP TABLE IF EXISTS product_lookup;

CREATE TABLE product_lookup AS
SELECT
    StockCode,
    Description AS ProductName
FROM (
    SELECT
        StockCode,
        Description,
        ROW_NUMBER() OVER (
            PARTITION BY StockCode
            ORDER BY COUNT(*) DESC, MAX(InvoiceDate) DESC
        ) AS description_rank
    FROM online_retail_clean
    GROUP BY StockCode, Description
) AS ranked_descriptions
WHERE description_rank = 1;