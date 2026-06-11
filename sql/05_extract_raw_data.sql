-- ================================================================
-- 05_extract_raw_data.sql — Manufacturing Data Extraction Query
-- ================================================================
-- PURPOSE:
--   This is the query that DataExtractor.run() executes via Python.
--   It joins products + production_runs + quality_checks +
--   supply_chain to produce raw-data.csv.
--
--   raw-data.csv is the input to Module 05 ETL.
--
-- WHY THIS QUERY EXISTS:
--   The database stores data efficiently in separate tables.
--   Analytics and ML need one flat table with all columns together.
--   This "denormalisation" step is what data extraction means.
--
-- THE DATA IS INTENTIONALLY MESSY:
--   After the seed scripts ran, the database may contain:
--     - NULL efficiency_pct values
--     - Missing quality inspections
--     - Missing delivery dates
--     - Missing maintenance records
--     - Extreme production volumes
--     - Unusual downtime values
--
--   Module 05 ETL will detect and fix these problems.
--   We leave them in the extraction deliberately.
--
-- CHANGE INDUSTRY BEFORE RUNNING:
--   The {industry} placeholder is replaced by Python with the
--   actual schema name from config.py.
-- ================================================================

SELECT

    -- ── Product Master Data ──────────────────────────────────────
    p.product_id,
    p.product_code,
    p.product_name,
    p.category,
    p.unit_cost,
    p.target_price,
    p.weight_kg,
    p.lead_time_days,
    p.is_active,

    -- ── Production Metrics (aggregated) ──────────────────────────
    prod_stats.total_runs,
    prod_stats.total_planned_units,
    prod_stats.total_actual_units,
    prod_stats.total_defective_units,
    prod_stats.avg_efficiency,
    prod_stats.total_downtime,

    -- ── Quality Metrics (aggregated) ─────────────────────────────
    quality_stats.total_checks,
    quality_stats.total_passed,
    quality_stats.total_failed,
    quality_stats.most_common_severity,

    -- ── Supply Chain Metrics (aggregated) ────────────────────────
    supply_stats.total_orders,
    supply_stats.total_material_cost,
    supply_stats.avg_unit_cost,

    -- ── Metadata ────────────────────────────────────────────────
    '{industry}'::VARCHAR AS source_schema,
    NOW()::DATE AS extracted_date

FROM {industry}.products p

-- Production aggregates per product
LEFT JOIN (
    SELECT
        product_id,

        COUNT(*) AS total_runs,

        SUM(planned_units) AS total_planned_units,

        SUM(actual_units) AS total_actual_units,

        SUM(defective_units) AS total_defective_units,

        ROUND(AVG(efficiency_pct)::NUMERIC, 2) AS avg_efficiency,

        SUM(downtime_mins) AS total_downtime

    FROM {industry}.production_runs

    GROUP BY product_id

) prod_stats
    ON p.product_id = prod_stats.product_id

-- Quality aggregates per product
LEFT JOIN (
    SELECT
        product_id,

        COUNT(*) AS total_checks,

        SUM(passed) AS total_passed,

        SUM(failed) AS total_failed,

        MAX(severity) AS most_common_severity

    FROM {industry}.quality_checks

    GROUP BY product_id

) quality_stats
    ON p.product_id = quality_stats.product_id

-- Supply chain aggregates per product
LEFT JOIN (
    SELECT
        product_id,

        COUNT(*) AS total_orders,

        ROUND(SUM(total_cost)::NUMERIC, 2) AS total_material_cost,

        ROUND(AVG(unit_cost)::NUMERIC, 2) AS avg_unit_cost

    FROM {industry}.supply_chain

    GROUP BY product_id

) supply_stats
    ON p.product_id = supply_stats.product_id

-- Easier CSV reading
ORDER BY
    p.category,
    p.product_id;