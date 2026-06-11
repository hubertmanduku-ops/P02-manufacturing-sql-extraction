# ======================================================================================================

## P02 ⭐⭐ — Manufacturing SQL Extraction

## The Darko Method 2026 | Student Data Engineering Project

---

## Project Overview

This project demonstrates end-to-end SQL-based data extraction and transformation for a manufacturing analytics use case.

It simulates a real-world scenario where a manufacturing company needs consolidated operational data from multiple systems to support data science initiatives, including defect prediction and production optimization.

The project connects to a PostgreSQL database hosted on Supabase, executes SQL queries against the `manufacturing` schema, and generates a structured dataset in CSV format for downstream analytics and ETL processing.

---

## Business Scenario

### Company

PrecisionCraft Industries

### Role

Data Analyst

PrecisionCraft operates across four manufacturing plants. Each plant generates large volumes of operational data across production systems, quality control systems, and equipment maintenance logs.

The Operations Director requires a unified dataset that enables:

* Production performance analysis
* Quality defect tracking
* Plant efficiency benchmarking
* Equipment reliability insights
* Data science model development (defect prediction)

To support this, data must be extracted and combined from multiple relational tables into a single analytics-ready dataset.

---

## Project Objective

The goal of this project is to:

* Connect to a PostgreSQL database using Supabase
* Write and execute SQL queries against the `manufacturing` schema
* Demonstrate SQL proficiency (joins, aggregations, CTEs, and window functions)
* Integrate production, quality, and equipment datasets
* Generate a clean, structured CSV file for analytics use
* Build a reusable data extraction pipeline using Python

---

## Data Sources

The project uses the following tables within the `manufacturing` schema:

| Table           | Description                              |
| --------------- | ---------------------------------------- |
| production_runs | Records of manufacturing production runs |
| quality_checks  | Quality inspection results for products  |
| equipment       | Machine and equipment details            |
| plants          | Manufacturing plant information          |
| products        | Product catalog information              |
| supply_chain    | Supply chain and logistics data          |

---

## Output Deliverable

The final output of this project is:

```text id="m3p2r8"
data/raw-data.csv
```

This file contains a joined and structured dataset combining production performance and quality metrics, ready for ETL pipelines and predictive analytics workflows.

---

## Technical Stack

* Python 3.x
* PostgreSQL (Supabase)
* SQL
* Pandas
* DBeaver
* Git & GitHub

---

## Project Structure

```text id="k9q1wp"
P02-manufacturing-sql/
│
├── data/
│   └── raw-data.csv
│
├── sql/
│   ├── 01_basics.sql
│   ├── 02_aggregation.sql
│   ├── 03_joins.sql
│   ├── 04_cte_window_functions.sql
│   └── 05_extract_raw_data.sql
│
├── src/
│   ├── config.py
│   ├── database.py
│   └── extractor.py
│
├── logs/
│
├── run.py
├── requirements.txt
├── .env
├── .gitignore
└── README.md
```

---

## Key SQL Concepts Covered

### Basic SQL

* SELECT queries
* WHERE filtering
* ORDER BY sorting

### Aggregations

* COUNT, SUM, AVG
* GROUP BY
* Defect rate calculations
* Efficiency metrics

### Joins

* INNER JOIN
* LEFT JOIN
* Multi-table joins across production and quality data

### Advanced SQL

* Common Table Expressions (CTEs)
* Window Functions
* Ranking production runs by efficiency per plant
* Partition-based analytics

---

## Data Pipeline Flow

1. Connect to Supabase PostgreSQL database
2. Query manufacturing schema tables
3. Extract production, quality, and equipment data
4. Join datasets into a unified analytical view
5. Load results into Python (Pandas)
6. Export final dataset as `raw-data.csv`

---

## Success Criteria

* Execute all required table queries successfully in DBeaver
* Build aggregation queries for defect rate and efficiency analysis
* Implement multi-table join for production + quality data
* Use at least one CTE or window function for ranking logic
* Generate `data/raw-data.csv` successfully using Python
* Maintain proper Git version control and push to GitHub

---

## Learning Outcomes

By completing this project, you will demonstrate:

* Advanced SQL querying skills
* Data modeling and integration techniques
* ETL pipeline design fundamentals
* Python-based data extraction
* Analytical thinking for manufacturing systems
* Git and GitHub workflow proficiency

---

## Author

Hubert Manduku

Data Analyst | SAP Consultant | Data Engineering Practitioner

This project is part of The Darko Method 2026 Data Engineering Program.
