# Dashboard

`online_retail_dashboard.pbix` is the four-page Power BI report. `online_retail_dashboard.pdf` is the same report as a PDF, and `overview.png` is a screenshot of the first page.

## Where the data comes from

The report reads five small summary tables in `data/`. Each one is the result of a query in
[`sql/11_export_dashboard_tables.sql`](../sql/11_export_dashboard_tables.sql), which also lists the totals each
result must match:

| File | Rows | Used for |
|---|---|---|
| `monthly_sales.csv` | 13 | Net sales trend, headline net sales and return rate |
| `country_sales.csv` | 38 | Net sales by country |
| `product_sales.csv` | 3,811 | Top products by revenue and units |
| `rfm_segments.csv` | 8 | Share of customers and revenue by RFM segment |
| `kpi_summary.csv` | 1 | Customers, orders, average and median order value |

## Rebuilding the tables

1. Run the pipeline scripts (`sql/01` to `sql/10`) so the clean table and product lookup exist.
2. Run each query in `sql/11_export_dashboard_tables.sql` and export the result as CSV into `data/`.
3. In Power BI Desktop, refresh the report (the file reads the CSVs from the author's local paths, so repoint the data sources first on another computer).
