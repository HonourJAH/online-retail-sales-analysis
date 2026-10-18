-- q01_gross_returns_net_sales.sql
-- Question: What are total gross sales, returns and net sales?
-- Reads:    online_retail_clean
-- Result:   gross 10,001,566.12 | returns -230,247.96 | net 9,771,318.16 | return rate 2.30%

WITH sales_totals AS (
    SELECT
        SUM(CASE WHEN is_cancellation = 0 THEN line_total END) AS gross_sales,
        SUM(CASE WHEN is_cancellation = 1 THEN line_total END) AS total_returns,
        SUM(line_total)                                        AS net_sales
    FROM online_retail_clean
)
SELECT
    gross_sales,
    total_returns,
    net_sales,
    ROUND(ABS(total_returns) * 100 / gross_sales, 2) AS return_rate_pct
FROM sales_totals;
