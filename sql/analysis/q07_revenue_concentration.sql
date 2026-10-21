-- q07_revenue_concentration.sql
-- Question: How concentrated is revenue among the top customers?
-- Reads:    online_retail_clean
-- Note:     net revenue, identified customers only (CustomerID IS NOT NULL).
--           15.41% of net revenue has no customer ID and is excluded from the shares.
--           4,361 customers = 4,333 with a sale + 28 who appear only through cancellations.

-- Top 10 customers with share and cumulative share
WITH customer_revenue AS (
    SELECT
        CustomerID,
        SUM(line_total) AS revenue
    FROM online_retail_clean
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
),
ranked_customers AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY revenue DESC) AS rank_no,
        CustomerID,
        revenue,
        revenue * 100 / SUM(revenue) OVER ()      AS share_pct,
        SUM(revenue) OVER (
            ORDER BY revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) * 100 / SUM(revenue) OVER ()            AS cum_share_pct
    FROM customer_revenue
)
SELECT
    rank_no,
    CustomerID,
    ROUND(revenue, 2)       AS revenue,
    ROUND(share_pct, 2)     AS share_pct,
    ROUND(cum_share_pct, 2) AS cum_share_pct
FROM ranked_customers
ORDER BY rank_no
LIMIT 10;

-- How fast the cumulative share climbs
WITH customer_revenue AS (
    SELECT
        CustomerID,
        SUM(line_total) AS revenue
    FROM online_retail_clean
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
),
ranked_customers AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY revenue DESC) AS rank_no,
        COUNT(*) OVER ()                          AS total_customers,
        SUM(revenue) OVER (
            ORDER BY revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) * 100 / SUM(revenue) OVER ()            AS cum_share_pct
    FROM customer_revenue
)
SELECT
    MAX(total_customers)                                              AS total_customers,
    MIN(CASE WHEN cum_share_pct >= 50 THEN rank_no END)               AS customers_for_50_pct,
    ROUND(MIN(CASE WHEN cum_share_pct >= 50 THEN rank_no END) * 100
          / MAX(total_customers), 2)                                  AS pct_of_customers_for_50,
    ROUND(MAX(CASE WHEN rank_no <= CEIL(total_customers * 0.1)
                   THEN cum_share_pct END), 2)                        AS top_10pct_customers_share
FROM ranked_customers;
