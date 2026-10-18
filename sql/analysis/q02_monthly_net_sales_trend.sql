-- q02_monthly_net_sales_trend.sql
-- Question: How do net sales trend month by month?
-- Reads:    online_retail_clean
-- Note:     December 2011 has only 9 days of data, so its change is not comparable.
--           Returns are counted in the month the cancellation was recorded.

WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(InvoiceDate, '%Y-%m') AS sales_month,
        SUM(line_total)                   AS net_sales
    FROM online_retail_clean
    GROUP BY sales_month
),
monthly_with_previous AS (
    SELECT
        sales_month,
        net_sales,
        LAG(net_sales) OVER (ORDER BY sales_month) AS previous_month_sales
    FROM monthly_sales
)
SELECT
    sales_month,
    net_sales,
    ROUND((net_sales - previous_month_sales) * 100 / previous_month_sales, 2) AS mom_change_pct
FROM monthly_with_previous
ORDER BY sales_month;
