Project Description
This project demonstrates a modern ETL pipeline using Snowflake and Power BI for Oslo Citi Bikes trip data. It covers loading raw CSV files (append), transforming data, and building data marts for analytics purposes.
Tech Stack

Snowflake
SQL
Power BI
optional: Python (for future API integration)

Data Source https://oslobysykkel.no/en/open-data (public datasets)

Architecture

Oslo Bikes Data Sources    
- CSV (monthly files)      
- GBFS API (optional)      
           │
           ▼
INGESTION LAYER            
(Python scripts)           
- read CSV / API           
- load to Snowflake RAW        
          
(scheduled via GitHub Actions)
           │
           ▼
SNOWFLAKE (RAW LAYER) 
           │
           ▼
DBT TRANSFORMATION LAYER   
- staging models          
- fact tables             
- KPI / marts             
           │
           ▼
BI LAYER                   
Power BI / dashboards      
- usage patterns           
- retention / peaks
