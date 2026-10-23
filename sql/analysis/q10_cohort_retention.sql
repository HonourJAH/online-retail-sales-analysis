-- q10_cohort_retention.sql
-- Question: Customer retention by monthly cohort
-- Reads:    online_retail_clean
-- Scope:    identified customers with at least one sale invoice (4,333 customers).
--           Cohort = month of a customer's first purchase in the data.
--           Active in a month = at least one sale order in that calendar month.
-- Caveats:  the data starts on 2010-12-01, so the 2010-12 cohort includes customers who
--           were established before the data begins. December 2011 has only 9 days of
--           data, so retention is reported only up to November 2011 (last complete month).
-- Check:    cohort sizes (m0) must total 4,333; all cells together must total 13,021.

-- Query 1: customers active in each month since their first purchase (counts)
WITH customer_months AS (
    SELECT DISTINCT
        CustomerID,
        CAST(DATE_FORMAT(InvoiceDate, '%Y-%m-01') AS DATE) AS purchase_month
    FROM online_retail_clean
    WHERE is_cancellation = 0
      AND CustomerID IS NOT NULL
),
customer_cohorts AS (
    SELECT
        CustomerID,
        purchase_month,
        MIN(purchase_month) OVER (PARTITION BY CustomerID) AS cohort_month
    FROM customer_months
),
cohort_activity AS (
    SELECT
        cohort_month,
        TIMESTAMPDIFF(MONTH, cohort_month, purchase_month) AS months_since_start,
        CustomerID
    FROM customer_cohorts
)
SELECT
    DATE_FORMAT(cohort_month, '%Y-%m')                                       AS cohort,
    COUNT(DISTINCT CASE WHEN months_since_start = 0  THEN CustomerID END)    AS m0,
    COUNT(DISTINCT CASE WHEN months_since_start = 1  THEN CustomerID END)    AS m1,
    COUNT(DISTINCT CASE WHEN months_since_start = 2  THEN CustomerID END)    AS m2,
    COUNT(DISTINCT CASE WHEN months_since_start = 3  THEN CustomerID END)    AS m3,
    COUNT(DISTINCT CASE WHEN months_since_start = 4  THEN CustomerID END)    AS m4,
    COUNT(DISTINCT CASE WHEN months_since_start = 5  THEN CustomerID END)    AS m5,
    COUNT(DISTINCT CASE WHEN months_since_start = 6  THEN CustomerID END)    AS m6,
    COUNT(DISTINCT CASE WHEN months_since_start = 7  THEN CustomerID END)    AS m7,
    COUNT(DISTINCT CASE WHEN months_since_start = 8  THEN CustomerID END)    AS m8,
    COUNT(DISTINCT CASE WHEN months_since_start = 9  THEN CustomerID END)    AS m9,
    COUNT(DISTINCT CASE WHEN months_since_start = 10 THEN CustomerID END)    AS m10,
    COUNT(DISTINCT CASE WHEN months_since_start = 11 THEN CustomerID END)    AS m11,
    COUNT(DISTINCT CASE WHEN months_since_start = 12 THEN CustomerID END)    AS m12
FROM cohort_activity
GROUP BY cohort_month
ORDER BY cohort_month;

-- Query 2: retention percentages for months 1, 2, 3 and 6
-- Cells that fall in an incomplete month (December 2011) are left blank (NULL).
WITH customer_months AS (
    SELECT DISTINCT
        CustomerID,
        CAST(DATE_FORMAT(InvoiceDate, '%Y-%m-01') AS DATE) AS purchase_month
    FROM online_retail_clean
    WHERE is_cancellation = 0
      AND CustomerID IS NOT NULL
),
customer_cohorts AS (
    SELECT
        CustomerID,
        purchase_month,
        MIN(purchase_month) OVER (PARTITION BY CustomerID) AS cohort_month
    FROM customer_months
),
cohort_activity AS (
    SELECT
        cohort_month,
        TIMESTAMPDIFF(MONTH, cohort_month, purchase_month) AS months_since_start,
        CustomerID
    FROM customer_cohorts
),
cohort_counts AS (
    SELECT
        cohort_month,
        TIMESTAMPDIFF(MONTH, cohort_month, '2011-11-01')                      AS complete_months_observed,
        COUNT(DISTINCT CASE WHEN months_since_start = 0 THEN CustomerID END)  AS m0,
        COUNT(DISTINCT CASE WHEN months_since_start = 1 THEN CustomerID END)  AS m1,
        COUNT(DISTINCT CASE WHEN months_since_start = 2 THEN CustomerID END)  AS m2,
        COUNT(DISTINCT CASE WHEN months_since_start = 3 THEN CustomerID END)  AS m3,
        COUNT(DISTINCT CASE WHEN months_since_start = 6 THEN CustomerID END)  AS m6
    FROM cohort_activity
    GROUP BY cohort_month
)
SELECT
    DATE_FORMAT(cohort_month, '%Y-%m')                                        AS cohort,
    m0                                                                        AS cohort_size,
    CASE WHEN complete_months_observed >= 1 THEN ROUND(m1 * 100 / m0, 1) END  AS month_1_pct,
    CASE WHEN complete_months_observed >= 2 THEN ROUND(m2 * 100 / m0, 1) END  AS month_2_pct,
    CASE WHEN complete_months_observed >= 3 THEN ROUND(m3 * 100 / m0, 1) END  AS month_3_pct,
    CASE WHEN complete_months_observed >= 6 THEN ROUND(m6 * 100 / m0, 1) END  AS month_6_pct
FROM cohort_counts
ORDER BY cohort_month;
