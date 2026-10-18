-- q04_top_products.sql
-- Question: Which 10 products generate the most revenue, and which sell the most units?
-- Reads:    online_retail_clean, product_lookup
-- Note:     net of returns. The join uses StockCode only; Description is a label.

-- Top 10 products by net revenue
SELECT
    clean_sales.StockCode,
    product_lookup.ProductName,
    SUM(clean_sales.line_total) AS net_revenue
FROM online_retail_clean AS clean_sales
JOIN product_lookup
    ON clean_sales.StockCode = product_lookup.StockCode
GROUP BY clean_sales.StockCode, product_lookup.ProductName
ORDER BY net_revenue DESC
LIMIT 10;

-- Top 10 products by net units sold
SELECT
    clean_sales.StockCode,
    product_lookup.ProductName,
    SUM(clean_sales.Quantity) AS net_units_sold
FROM online_retail_clean AS clean_sales
JOIN product_lookup
    ON clean_sales.StockCode = product_lookup.StockCode
GROUP BY clean_sales.StockCode, product_lookup.ProductName
ORDER BY net_units_sold DESC
LIMIT 10;

-- Reconciliation: net revenue across all products must equal Q1 net sales (9,771,318.16)
SELECT SUM(clean_sales.line_total) AS net_revenue_all_products
FROM online_retail_clean AS clean_sales
JOIN product_lookup
    ON clean_sales.StockCode = product_lookup.StockCode;
