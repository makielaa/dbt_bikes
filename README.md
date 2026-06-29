# Oslo City Bikes — Data Pipeline

End-to-end data pipeline for Oslo City Bikes public trip data.

## Architecture
Oslo City Bikes API (monthly CSV)

↓

Python loader (incremental)

↓

Snowflake — STAGE.BIKES_STATIONS

↓

dbt — staging → intermediate → marts

↓

Power BI dashboards

## Tech Stack

- **Python** — incremental data loading from Oslo City Bikes API
- **Snowflake** — cloud data warehouse
- **dbt Cloud** — data transformation and modeling
- **GitHub Actions** — pipeline orchestration (daily at 6:00 CET)
- **Power BI** — dashboards and analytics

## Data Source

[Oslo City Bikes Open Data](https://oslobysykkel.no/en/open-data) — public monthly trip data

## dbt Project Structure
models/

├── staging/        # raw data cleaning and deduplication

├── intermediate/   # enriched trip-level data

└── marts/          # aggregated models for BI

├── mart_routes.sql

└── (more marts coming)

## Pipeline

Runs automatically every day via GitHub Actions:
1. Python script loads new month data to Snowflake (data updated daily at ublic monthly trip data)
2. dbt build transforms and tests all models
3. Power BI refresh (manual)
