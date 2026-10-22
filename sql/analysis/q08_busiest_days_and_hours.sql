-- q08_busiest_days_and_hours.sql
-- Question: What are the busiest days of the week and hours of the day?
-- Reads:    online_retail_clean
-- Note:     sale invoices only (cancellations excluded). There are no Saturday orders.
--           Hourly order counts add to 19,772, one above the true total of 19,771, because
--           invoice 549245 has lines in two different hours (11:59 and 12:00) and is counted in both.

-- By day of week
SELECT
    DAYOFWEEK(InvoiceDate)  AS day_no,
    DAYNAME(InvoiceDate)    AS day_name,
    COUNT(DISTINCT Invoice) AS orders,
    SUM(line_total)         AS gross_sales
FROM online_retail_clean
WHERE is_cancellation = 0
GROUP BY day_no, day_name
ORDER BY day_no;

-- By hour of day
SELECT
    HOUR(InvoiceDate)       AS `hour`,
    COUNT(DISTINCT Invoice) AS orders,
    SUM(line_total)         AS gross_sales
FROM online_retail_clean
WHERE is_cancellation = 0
GROUP BY `hour`
ORDER BY `hour`;

-- Why the hourly orders add to 19,772: invoices with lines in more than one hour
SELECT
    Invoice,
    COUNT(DISTINCT HOUR(InvoiceDate)) AS hours_spanned,
    MIN(InvoiceDate)                  AS first_line,
    MAX(InvoiceDate)                  AS last_line
FROM online_retail_clean
WHERE is_cancellation = 0
GROUP BY Invoice
HAVING hours_spanned > 1;
