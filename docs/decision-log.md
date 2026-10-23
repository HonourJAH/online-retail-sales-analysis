# Decision log: Online Retail II cleaning

Every cleaning decision in this project, with the evidence that led to it. Nothing was removed
from the data silently: excluded rows are labelled in `online_retail_flagged.exclusion_reason`,
and every count below can be reproduced with the scripts in `sql/`.

## Process

1. Load the CSV unchanged into an all-text raw table (`01_load_raw.sql`).
2. Profile the raw table: completeness, value formats, price precision (`02_profile_raw.sql`).
3. Convert to proper types in a staging table (`03_build_staging.sql`).
4. Profile the staging table for validity, duplicates, non-product codes and outliers (`04_profile_staging.sql`).
5. Flag every row with an exclusion reason instead of deleting it (`05_build_flagged.sql`).
6. Validate the flags, build the clean table and the product lookup, and validate both (`06` to `10`).

Row reconciliation: 541,910 rows in, 10,709 excluded, 531,201 kept.

## Load and type checks

- Row count after loading: 541,910, matching the file.
- Blank values in raw: 1,454 descriptions and 135,080 Customer IDs (24.9%). No blanks in the other columns.
- Customer ID, Quantity and Price contain only valid numbers (checked with pattern matches), so converting them to numeric types cannot alter a value.
- Four prices have three decimals (all 0.001: three PADS rows and one BANK CHARGES row). A DECIMAL(10,2) column would have rounded them to zero, so staging uses DECIMAL(10,3). The true zero-price row count is 2,515.
- All dates parse correctly (no NULL dates). Range: 2010-12-01 to 2011-12-09.

## Decisions

### 1. Non-product codes: excluded (2,951 rows)

Postage, carriage, manual entries, fees, discounts, samples and adjustments are not product sales.
They are excluded by StockCode, never by Description, because one code can carry several descriptions.

| StockCode | Meaning | Rows |
|---|---|---|
| POST | Postage | 1,257 |
| DOT | Dotcom postage | 710 |
| M | Manual | 572 |
| C2 | Carriage | 144 |
| D | Discount | 77 |
| S | Samples | 63 |
| BANK CHARGES | Bank charges | 37 |
| AMAZONFEE | Amazon fee | 34 |
| CRUK | CRUK commission | 16 |
| B | Adjust bad debt | 3 |
| PADS | Pads to match all cushions (token price 0.001) | 4 |
| gift_0001_* | Dotcom gift shop vouchers | 34 |

Not excluded: 45 rows with `DCGS...` codes. They are real products (for example a boxed glass ashtray).
12 of them have a zero price and are excluded under decision 3. The other 33 are kept.

### 2. Matched same-day reversal pairs: excluded (4 rows)

Customer 12346 ordered 74,215 units of StockCode 23166 and cancelled the same order 16 minutes later.
Customer 16446 ordered 80,995 units of StockCode 23843 and cancelled it 12 minutes later.
Left in as sales, they would add about 245,653 of gross sales (about 2.4% of gross product sales).

A broader search for same-day reversals found only false positives (for example a cancellation followed
by a re-order of the same quantity), so no other pairs are excluded.

### 3. Zero price: excluded (2,497 rows, plus 18 labelled under decision 1)

- 1,336 rows have a negative quantity, zero price, no customer and no invoice prefix. Their descriptions are
  staff notes such as "damaged", "check" and "thrown away", so they are internal stock adjustments.
- 1,179 rows have a positive quantity and zero price. 1,139 have no customer and mostly carry notes
  ("check", "Found", "amazon"). 40 have a customer and look like zero-priced shipments, but the data
  does not say why, so no cause is claimed.
- A zero-price row adds no revenue but would inflate units, line counts and order counts.
- All 1,454 NULL-description rows have a zero price, so none is a real sale.

### 4. Exact duplicates: extra copies excluded, one kept (5,257 rows)

Rows identical on all eight columns: 4,879 repeated groups with 5,268 extra copies in staging
(11 of those are labelled under a higher-priority reason, leaving 5,257 labelled as duplicates).

Duplicates cannot be proven to be errors. Some are probably genuine repeated scans (for example 20 identical
lines of one teacup on one invoice). The decision assumes they are repeated captures. Worst case, if every
removed copy was a real sale, the sales value lost is 21,740.98, about 0.21% of gross product sales.

### 5. Cancellations: kept and flagged (8,666 rows)

Invoices starting with C are kept with `is_cancellation = 1` and a negative `line_total`, so returns net
correctly against sales. Dropping them would leave the original orders in as sales. In the clean table,
every cancellation row has a negative quantity and every other row a positive one.

### 6. Blank Customer ID: kept

About a quarter of raw rows (and 15.41% of net revenue in the clean table) have no customer. The sales are
real, so the rows stay. Customer-level analysis (questions 6, 7, 9 and 10) covers identified customers only.

### 7. Several descriptions per StockCode: StockCode is the key

639 product codes have more than one description; 212 still do after excluding zero-price rows. The
differences are typos (DOILEY and DOILY), rewordings and staff notes. `product_lookup` holds one name per
code: the most frequently used description, with the most recent use breaking ties. Joins use StockCode only.
Joining on Description as well silently dropped rows in an early version, which a reconciliation to total net
sales caught.

### 8. Country labels: three renamed

38 distinct values and no spelling variants. EIRE, RSA and USA are renamed Ireland, South Africa and
United States. Kept as they are: Unspecified (446 real sales worth 4,749.79), European Community and
Channel Islands, which are labels and not single countries.

## Exclusion priority

Each excluded row gets one reason, the first that applies: non_product_code (2,951), matched_reversal_pair (4),
zero_price (2,497), exact_duplicate (5,257). This is why the zero-price count in the flags (2,497) is lower
than the 2,515 true zero-price rows: 18 of them are non-product codes.

## Assumptions and limits

- Exact duplicates are assumed to be repeated captures.
- The currency is not stated; values are probably pounds sterling.
- December 2011 contains only nine days of data.
- The data starts on 2010-12-01, so "first purchase" means first purchase in the data.
