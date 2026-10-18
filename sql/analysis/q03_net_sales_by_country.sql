-- q03_net_sales_by_country.sql
-- Question: Which countries generate the most revenue?
-- Reads:    online_retail_clean
-- Note:     net sales (returns included). Unspecified, European Community and
--           Channel Islands are labels, not single countries.

WITH revenue_by_country AS (
    SELECT
        Country,
        SUM(line_total) AS net_sales
    FROM online_retail_clean
    GROUP BY Country
)
SELECT
    Country,
    net_sales,
    ROUND(net_sales * 100 / SUM(net_sales) OVER (), 2) AS revenue_share_pct
FROM revenue_by_country
ORDER BY net_sales DESC;
