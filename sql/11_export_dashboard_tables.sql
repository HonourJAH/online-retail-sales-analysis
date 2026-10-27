-- 11_export_dashboard_tables.sql
-- Purpose: the five summary tables that the Power BI dashboard reads (dashboard/data/*.csv).
-- Reads:   online_retail_clean, product_lookup
-- How:     run each query, then export its result grid as CSV into dashboard/data/.
--          In MySQL Workbench, set "Limit to 1000 rows" to "Don't Limit" first,
--          or the product table is cut off at 1,000 rows (it must have 3,811).

-- 1. monthly_sales.csv
-- Check: 13 rows; gross 10,001,566.12 | returns -230,247.96 | net 9,771,318.16
SELECT
    DATE_FORMAT(InvoiceDate, '%Y-%m-01')                       AS sales_month,
    SUM(CASE WHEN is_cancellation = 0 THEN line_total END)     AS gross_sales,
    SUM(CASE WHEN is_cancellation = 1 THEN line_total END)     AS returns_value,
    SUM(line_total)                                            AS net_sales
FROM online_retail_clean
GROUP BY sales_month
ORDER BY sales_month;

-- 2. country_sales.csv
-- Check: 38 rows; net sales total 9,771,318.16; United Kingdom first at 8,281,390.36
SELECT
    Country,
    SUM(line_total) AS net_sales
FROM online_retail_clean
GROUP BY Country
ORDER BY net_sales DESC;

-- 3. product_sales.csv
-- Check: 3,811 rows; net revenue total 9,771,318.16; first row 22423 at 164,459.49
SELECT
    clean_sales.StockCode,
    product_lookup.ProductName,
    SUM(clean_sales.line_total) AS net_revenue,
    SUM(clean_sales.Quantity)   AS net_units_sold
FROM online_retail_clean AS clean_sales
JOIN product_lookup
    ON clean_sales.StockCode = product_lookup.StockCode
GROUP BY clean_sales.StockCode, product_lookup.ProductName
ORDER BY net_revenue DESC;

-- 4. rfm_segments.csv
-- Check: 8 rows; customers total 4,333; revenue total 8,491,574.44; Champions 816 customers
WITH customer_rfm AS (
    SELECT
        CustomerID,
        DATEDIFF('2011-12-10', MAX(DATE(InvoiceDate))) AS recency_days,
        COUNT(DISTINCT Invoice)                        AS frequency,
        SUM(line_total)                                AS monetary
    FROM online_retail_clean
    WHERE is_cancellation = 0
      AND CustomerID IS NOT NULL
    GROUP BY CustomerID
),
scored_customers AS (
    SELECT
        CustomerID,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score,
        CASE
            WHEN frequency = 1               THEN 1
            WHEN frequency = 2               THEN 2
            WHEN frequency BETWEEN 3 AND 4   THEN 3
            WHEN frequency BETWEEN 5 AND 10  THEN 4
            ELSE 5
        END                                        AS frequency_score
    FROM customer_rfm
),
customer_segments AS (
    SELECT
        CustomerID,
        recency_days,
        frequency,
        monetary,
        CASE
            WHEN recency_score >= 4 AND frequency_score >= 4        THEN 'Champions'
            WHEN recency_score IN (2, 3) AND frequency_score >= 4   THEN 'Loyal'
            WHEN recency_score = 1 AND frequency_score >= 4         THEN 'At Risk'
            WHEN recency_score >= 4 AND frequency_score = 1         THEN 'New Customers'
            WHEN recency_score >= 4 AND frequency_score IN (2, 3)   THEN 'Potential Loyalists'
            WHEN recency_score = 3                                  THEN 'Need Attention'
            WHEN recency_score = 2                                  THEN 'About to Sleep'
            ELSE 'Lost'
        END AS segment
    FROM scored_customers
)
SELECT
    segment,
    COUNT(*)                     AS customers,
    ROUND(SUM(monetary), 2)      AS revenue,
    ROUND(AVG(recency_days), 0)  AS avg_recency_days,
    ROUND(AVG(frequency), 1)     AS avg_orders
FROM customer_segments
GROUP BY segment
ORDER BY revenue DESC;

-- 5. kpi_summary.csv
-- Check: 4,333 customers | 19,771 orders | 1,371 without customer | average 505.87 | median 302.20 | largest 52,940.94
WITH invoice_totals AS (
    SELECT
        Invoice,
        MAX(CustomerID) AS customer_id,
        SUM(line_total) AS invoice_total
    FROM online_retail_clean
    WHERE is_cancellation = 0
    GROUP BY Invoice
),
ranked_invoices AS (
    SELECT
        invoice_total,
        ROW_NUMBER() OVER (ORDER BY invoice_total) AS position_in_order,
        COUNT(*) OVER ()                           AS total_orders
    FROM invoice_totals
),
median_value AS (
    SELECT AVG(invoice_total) AS median_gross_order_value
    FROM ranked_invoices
    WHERE position_in_order IN (FLOOR((total_orders + 1) / 2),
                                CEIL((total_orders + 1) / 2))
)
SELECT
    COUNT(DISTINCT customer_id)                                   AS customers,
    COUNT(*)                                                      AS orders,
    SUM(customer_id IS NULL)                                      AS orders_without_customer,
    ROUND(AVG(invoice_total), 2)                                  AS avg_gross_order_value,
    ROUND((SELECT median_gross_order_value FROM median_value), 2) AS median_gross_order_value,
    ROUND(MAX(invoice_total), 2)                                  AS largest_order_value
FROM invoice_totals;
