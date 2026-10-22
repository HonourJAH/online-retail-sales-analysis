-- q09_rfm_segmentation.sql
-- Question: Customer segmentation with RFM (recency, frequency, monetary value)
-- Reads:    online_retail_clean
-- Scope:    identified customers with at least one sale invoice (4,333 customers).
--           Recency is measured to 2011-12-10, the day after the data ends.
-- Scoring:  recency and monetary value use quintiles (NTILE). Frequency uses fixed bands
--           (1, 2, 3-4, 5-10, 11+ orders), because 34.7% of customers placed exactly one
--           order and NTILE would split identical customers between scores.
-- Segments: rules are an analyst's judgement, not a standard. They are applied top to bottom.
-- Check:    customers must total 4,333 and revenue 8,491,574.44.

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
    COUNT(*)                                                     AS customers,
    ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (), 1)             AS pct_of_customers,
    ROUND(SUM(monetary), 2)                                      AS revenue,
    ROUND(SUM(monetary) * 100 / SUM(SUM(monetary)) OVER (), 1)   AS pct_of_revenue,
    ROUND(AVG(recency_days), 0)                                  AS avg_recency_days,
    ROUND(AVG(frequency), 1)                                     AS avg_orders
FROM customer_segments
GROUP BY segment
ORDER BY revenue DESC;
