# Online Retail Sales Analysis: Cleaning, Profiling and Customer Insights in MySQL

An end-to-end SQL analysis of a UK online retailer's transactions (Dec 2010 to Dec 2011). The project profiles and cleans a messy transactional dataset with every decision documented and auditable, then answers business questions on sales, products, countries and customers.

**Status:** data profiling and cleaning complete; business questions in progress.

## Dataset

- **Source:** Online Retail II, UCI Machine Learning Repository
- **Size:** 541,910 transaction lines, 2010-12-01 to 2011-12-09
- **Columns:** Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer ID, Country
- The CSV is not included in this repository. See `data/README.md` for how to download it.

## Tools

- MySQL 8.0 (SQL: CTEs, window functions, conditional aggregation)
- Git and GitHub
- Planned: Excel, Power BI and pandas for the dashboard and extra analysis

## Approach: layered tables

The data is never modified in place. Each layer is built from the one before it.

| Layer | Table | Rows | Purpose |
|---|---|---|---|
| Raw | `online_retail_raw` | 541,910 | The file exactly as loaded, all text. Never changed. |
| Staging | `online_retail_stg` | 541,910 | Same rows with proper data types. |
| Flagged | `online_retail_flagged` | 541,910 | Staging plus an `exclusion_reason` for each excluded row. |
| Clean | `online_retail_clean` | 531,201 | The table used for analysis, with `is_cancellation` and `line_total`. |
| Lookup | `product_lookup` | 3,811 | One product name per StockCode. |

Rows are flagged with a reason instead of being deleted, so every exclusion can be counted and traced: 541,910 rows in, 10,709 excluded, 531,201 kept.

## Data cleaning decisions

| # | Finding | Rows | Decision |
|---|---|---|---|
| 1 | Non-product codes (postage, manual entries, fees, discounts, samples, bad-debt adjustments, vouchers) | 2,951 | Excluded, filtered by StockCode |
| 2 | Matched same-day reversal pairs (two customers, about 2.4% of gross product sales if left in) | 4 | Excluded |
| 3 | Zero price (internal stock adjustments and unpriced lines) | 2,497 | Excluded |
| 4 | Exact duplicates (all 8 columns identical) | 5,257 | Extra copies excluded, one kept. Worst-case sales impact about 0.21% |
| 5 | Cancellations (invoices starting with C) | 8,666 | Kept and flagged with `is_cancellation` so returns net correctly |
| 6 | Blank Customer ID (24.9% of raw rows) | 135,080 | Kept; limits customer-level analysis only |
| 7 | Several descriptions per StockCode | 212 codes | StockCode is the product key; names come from `product_lookup` |
| 8 | Country labels | 3 renamed | EIRE, RSA and USA standardized; Unspecified kept |
| 9 | Prices with 3 decimals | 4 | Staging uses DECIMAL(10,3) so nothing is rounded |

## Repository structure

```
sql/    numbered scripts, run in order (01 to 10)
data/   instructions for the dataset (the CSV itself is not committed)
docs/   supporting notes and the decision log
```

## How to reproduce

1. Download the dataset and place it as described in `data/README.md`.
2. Follow the setup notes at the top of `sql/01_load_raw.sql` (the file path must match your MySQL upload folder).
3. Run the scripts in `sql/` in numbered order. Each `validate` script lists the result it should produce.

## Key findings

_To be completed after the business questions are finalized._

## Author

Michael ([@HonourJAH](https://github.com/HonourJAH))