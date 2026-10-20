-- q06_customers_and_order_value.sql
-- Question: How many customers are there, and what is the average order value?
-- Reads:    online_retail_clean
-- Note:     sale invoices only (cancellations excluded); orders without a CustomerID are counted
--           as orders but cannot be counted as customers.
-- Result:   customers 4,333 | orders 19,771 | orders without customer 1,371
--           average 505.87 | median 302.20 | largest order 52,940.94

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
