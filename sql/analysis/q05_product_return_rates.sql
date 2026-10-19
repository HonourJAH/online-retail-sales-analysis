-- q05_product_return_rates.sql
-- Question: Which products have the highest return rate?
-- Reads:    online_retail_clean, product_lookup
-- Method:   line return rate = return lines / sale lines. Counting lines instead of units
--           stops one large cancellation from dominating the ranking.
-- Filter:   products with at least 100 sale lines (1,550 of 3,811 products).

-- Final ranking: top 10 products by line return rate
WITH product_line_counts AS (
    SELECT
        clean_sales.StockCode,
        product_lookup.ProductName,
        COUNT(CASE WHEN clean_sales.is_cancellation = 0 THEN 1 END)          AS sale_lines,
        COUNT(CASE WHEN clean_sales.is_cancellation = 1 THEN 1 END)          AS return_lines,
        MAX(CASE WHEN clean_sales.is_cancellation = 1 THEN ABS(clean_sales.Quantity) END) AS largest_single_return
    FROM online_retail_clean AS clean_sales
    JOIN product_lookup
        ON clean_sales.StockCode = product_lookup.StockCode
    GROUP BY clean_sales.StockCode, product_lookup.ProductName
    HAVING sale_lines >= 100
)
SELECT
    StockCode,
    ProductName,
    sale_lines,
    return_lines,
    largest_single_return,
    ROUND(return_lines * 100 / sale_lines, 2) AS line_return_rate_pct
FROM product_line_counts
ORDER BY line_return_rate_pct DESC
LIMIT 10;

-- Why not units: ranking by units returned puts one 9,360-unit cancellation
-- (StockCode 84347, invoice C536757) first at 99.10%.
WITH product_unit_counts AS (
    SELECT
        clean_sales.StockCode,
        product_lookup.ProductName,
        ABS(SUM(CASE WHEN clean_sales.is_cancellation = 1 THEN clean_sales.Quantity END)) AS units_returned,
        SUM(CASE WHEN clean_sales.is_cancellation = 0 THEN clean_sales.Quantity END)      AS units_sold
    FROM online_retail_clean AS clean_sales
    JOIN product_lookup
        ON clean_sales.StockCode = product_lookup.StockCode
    GROUP BY clean_sales.StockCode, product_lookup.ProductName
    HAVING units_sold >= 500
)
SELECT
    StockCode,
    ProductName,
    units_returned,
    units_sold,
    ROUND(units_returned * 100 / units_sold, 2) AS unit_return_rate_pct
FROM product_unit_counts
ORDER BY unit_return_rate_pct DESC
LIMIT 10;

-- Reconciliation: line totals must equal the clean table (522,535 sale lines, 8,666 return lines)
SELECT
    COUNT(CASE WHEN clean_sales.is_cancellation = 0 THEN 1 END) AS total_sale_lines,
    COUNT(CASE WHEN clean_sales.is_cancellation = 1 THEN 1 END) AS total_return_lines
FROM online_retail_clean AS clean_sales
JOIN product_lookup
    ON clean_sales.StockCode = product_lookup.StockCode;
