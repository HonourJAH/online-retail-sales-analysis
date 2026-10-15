-- 08_validate_clean.sql
-- Purpose: check that the clean table is correct and nothing excluded leaked in.
--          Covers row count (531,201), excluded values, standardized country names,
--          and quantity sign against is_cancellation.
-- Reads:   online_retail_clean


-- confirm the row count
SELECT COUNT(*) AS clean_rows
FROM online_retail_clean;


-- check that nothing excluded leaked in and the country names were standardized
SELECT
    SUM(Price <= 0)                                   AS non_positive_price,
    SUM(StockCode IN ('POST','DOT','M','C2','D','S','BANK CHARGES',
                      'AMAZONFEE','CRUK','B','PADS')
        OR StockCode LIKE 'gift\_%')                  AS non_product_rows,
    SUM(Country IN ('EIRE','RSA','USA'))              AS old_country_names,
    SUM(Description IS NULL)                          AS null_description
FROM online_retail_clean;


-- cross-check quantity sign against the cancellation flag
SELECT
    is_cancellation,
    SUM(Quantity < 0)  AS negative_qty,
    SUM(Quantity > 0)  AS positive_qty,
    COUNT(*)           AS n_rows
FROM online_retail_clean
GROUP BY is_cancellation;


-- the grouped counts for one code
SELECT
    StockCode,
    Description,
    COUNT(*)         AS rows_with_this_description,
    MAX(InvoiceDate) AS last_used
FROM online_retail_clean
WHERE StockCode = '23236'
GROUP BY StockCode, Description
ORDER BY rows_with_this_description DESC, last_used DESC;