# Oslo City Bikes — Data Pipeline

End-to-end data pipeline for Oslo City Bikes public trip data.

## Architecture
Oslo City Bikes API (monthly CSV, daily JSON)

↓

Python loader (incremental):
1. Oslo City Bikes historical data - monthly files; loaded on weekly basis
2. Oslo City Bikes stations availability - daily load (for time trends analysis)

↓

Snowflake:
1. STAGE.BIKES_STATIONS
2. STAGE.SNAPSHOT

↓

dbt — staging → intermediate → marts
1. stage files
2. stage Tables
3. intermediate marts
4. 

↓

Power BI dashboards

## Tech Stack

- **Python** — incremental data loading from Oslo City Bikes API
- **Snowflake** — cloud data warehouse
- **dbt Cloud** — data transformation and modeling
- **GitHub Actions** — pipeline orchestration (weekly and daily Python load --> dbt run)
- **Power BI** — dashboards and analytics

## Data Source

[Oslo City Bikes Open Data](https://oslobysykkel.no/en/open-data) — public monthly and realtime trip data


## dbt Project Structure
models/

├── staging/        # raw data cleaning and deduplication

├── intermediate/   # enriched trip-level data
                    # enriched stations data

└── marts/          # aggregated models for BI

├── mart_routes.sql
└── mart_stations.sql
└── mart_station_availability.sql


## Pipeline

Runs automatically every day via GitHub Actions:
1. Python script loads new month data to Snowflake (data updated daily at ublic monthly trip data)
2. dbt build transforms and tests all models
3. Power BI refresh (manual)
