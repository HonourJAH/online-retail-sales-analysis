-- 01_load_raw.sql
-- Purpose: load the Online Retail II CSV exactly as it appears in the file.
-- Builds:  online_retail_raw (all columns text, no transformations)
-- Note:    never UPDATE or DELETE on this table after loading.
--
-- Before running:
--   1. Download the dataset (see data/README.md).
--   2. Find your MySQL upload folder by running:
--        SHOW VARIABLES LIKE 'secure_file_priv';
--   3. Copy online_retail_II.csv into that folder.
--   4. Change the path in LOAD DATA INFILE below to match it.
--      (The path below is the author's own Windows path, shown as an example.)

DROP TABLE IF EXISTS online_retail_raw;

CREATE TABLE online_retail_raw (
    Invoice       VARCHAR(50),
    StockCode     VARCHAR(50),
    `Description` VARCHAR(500),
    Quantity      VARCHAR(50),
    InvoiceDate   VARCHAR(50),
    Price         VARCHAR(50),
    `Customer ID` VARCHAR(50),
    Country       VARCHAR(100)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\online_retail_II.csv'
INTO TABLE online_retail_raw
CHARACTER SET latin1
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r'
IGNORE 1 LINES;