-- ================================================================
-- 04_advanced.sql — Window Functions, CTEs, and Subqueries
-- ================================================================
-- These are the SQL features that separate junior from senior
-- data professionals. They are used in every production data pipeline.
--
-- WINDOW FUNCTIONS: compute a value for each row using a "window"
--   of related rows (without collapsing to one row like GROUP BY).
--   "What is each employee's salary RANK within their department?"
--
-- CTEs (Common Table Expressions): named temporary result sets.
--   Break a complex query into readable, named steps.
--   Defined with the WITH keyword.
--
-- SUBQUERIES: a query nested inside another query.
--   The inner query runs first; the outer query uses its result.
-- ================================================================

-- ================================================================
-- SECTION 1: Window Functions
-- ================================================================
-- SYNTAX:
--   function() OVER (
--       PARTITION BY column
--       ORDER BY column
--   )
--
-- KEY DIFFERENCE FROM GROUP BY:
--   GROUP BY: 1 plant → 1 row (summary)
--   PARTITION BY: all production runs remain visible,
--                 but each row gets plant-level calculations
-- ================================================================


-- ================================================================
-- QUERY 1: Rank Production Runs by Efficiency Within Each Plant
-- ================================================================
-- BUSINESS QUESTION:
--   Which production runs performed best within each plant?
--
-- WINDOW FUNCTION:
--   RANK()
--
-- PARTITION BY:
--   plant_id
--
-- ORDER BY:
--   efficiency_pct DESC
-- ================================================================

SELECT
    run_id,
    plant_id,
    product_id,
    run_date,
    shift,
    efficiency_pct,

    RANK() OVER (
        PARTITION BY plant_id
        ORDER BY efficiency_pct DESC
    ) AS efficiency_rank

FROM manufacturing.production_runs

ORDER BY plant_id, efficiency_rank;


-- ================================================================
-- QUERY 2: Compare Each Run Against Plant Average Efficiency
-- ================================================================
-- BUSINESS QUESTION:
--   Is this production run performing above or below the
--   average efficiency of its plant?
--
-- WINDOW FUNCTION:
--   AVG()
--
-- PARTITION BY:
--   plant_id
-- ================================================================

SELECT
    run_id,
    plant_id,
    efficiency_pct,

    ROUND(
        AVG(efficiency_pct) OVER (
            PARTITION BY plant_id
        ),
        2
    ) AS plant_avg_efficiency,

    ROUND(
        efficiency_pct -
        AVG(efficiency_pct) OVER (
            PARTITION BY plant_id
        ),
        2
    ) AS variance_from_avg

FROM manufacturing.production_runs

ORDER BY plant_id, efficiency_pct DESC;


-- ================================================================
-- QUERY 3: Running Production Total by Plant
-- ================================================================
-- BUSINESS QUESTION:
--   How much production output has each plant accumulated
--   over time?
--
-- WINDOW FUNCTION:
--   SUM()
--
-- PARTITION BY:
--   plant_id
--
-- ORDER BY:
--   run_date
-- ================================================================

SELECT
    run_id,
    plant_id,
    run_date,
    actual_units,

    SUM(actual_units) OVER (
        PARTITION BY plant_id
        ORDER BY run_date
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    ) AS cumulative_output

FROM manufacturing.production_runs

ORDER BY plant_id, run_date;


-- ================================================================
-- QUERY 4: Supplier Spend Ranking
-- ================================================================
-- BUSINESS QUESTION:
--   Which suppliers account for the highest material spend?
--
-- WINDOW FUNCTION:
--   DENSE_RANK()
--
-- NOTE:
--   First aggregate supplier spending,
--   then rank suppliers by total spend.
-- ================================================================

WITH supplier_spend AS (

    SELECT
        supplier_name,

        SUM(total_cost) AS total_spend

    FROM manufacturing.supply_chain

    GROUP BY supplier_name
)

SELECT
    supplier_name,
    total_spend,

    DENSE_RANK() OVER (
        ORDER BY total_spend DESC
    ) AS supplier_rank

FROM supplier_spend

ORDER BY supplier_rank;

-- ================================================================
-- SECTION 2: CTEs (Common Table Expressions)
-- ================================================================
-- Syntax:
--   WITH cte_name AS (
--       SELECT ...
--   )
--   SELECT ... FROM cte_name ...
--
-- WHY USE CTEs?
--   Without CTEs, complex queries become deeply nested and unreadable.
--   CTEs give each step a name, making the logic clear and debuggable.
--   You can even define multiple CTEs in one query (separated by commas).
-- ================================================================


-- ================================================================
-- QUERY 1: Top Performing Plants by Average Efficiency
-- ================================================================
-- BUSINESS QUESTION:
--   Which plants have the highest average production efficiency?
--
-- CTE PURPOSE:
--   First calculate plant-level production statistics.
--   Then rank and filter the results.
-- ================================================================

WITH plant_performance AS (

    SELECT
        plant_id,

        COUNT(*) AS total_runs,

        SUM(actual_units) AS total_output,

        ROUND(AVG(efficiency_pct), 2) AS avg_efficiency

    FROM manufacturing.production_runs

    GROUP BY plant_id
)

SELECT
    plant_id,
    total_runs,
    total_output,
    avg_efficiency

FROM plant_performance

ORDER BY avg_efficiency DESC

LIMIT 5;


-- ================================================================
-- QUERY 2: Product Quality Analysis
-- ================================================================
-- BUSINESS QUESTION:
--   Which products generate the most defects?
--
-- CTE PURPOSE:
--   Aggregate defect information by product first,
--   then join to product master data.
-- ================================================================

WITH product_defects AS (

    SELECT
        product_id,

        SUM(failed) AS total_failed_samples,

        COUNT(*) AS inspections

    FROM manufacturing.quality_checks

    GROUP BY product_id
)

SELECT
    p.product_name,
    p.category,

    pd.inspections,
    pd.total_failed_samples

FROM product_defects pd

INNER JOIN manufacturing.products p
    ON pd.product_id = p.product_id

ORDER BY pd.total_failed_samples DESC

LIMIT 10;


-- ================================================================
-- QUERY 3: Supply Chain Cost Analysis
-- ================================================================
-- BUSINESS QUESTION:
--   Which suppliers contribute the highest material costs?
--
-- CTE PURPOSE:
--   Step 1: Calculate supplier spending.
--   Step 2: Categorize suppliers by spend level.
--
-- MULTIPLE CTE EXAMPLE
-- ================================================================

WITH supplier_costs AS (

    SELECT
        supplier_name,

        SUM(total_cost) AS total_spend

    FROM manufacturing.supply_chain

    GROUP BY supplier_name
),

supplier_categories AS (

    SELECT
        supplier_name,
        total_spend,

        CASE
            WHEN total_spend >= 100000 THEN 'Strategic Supplier'
            WHEN total_spend >= 50000 THEN 'Major Supplier'
            ELSE 'Standard Supplier'
        END AS supplier_tier

    FROM supplier_costs
)

SELECT
    supplier_name,
    total_spend,
    supplier_tier

FROM supplier_categories

ORDER BY total_spend DESC;

-- ================================================================
-- SECTION 3: Subqueries
-- ================================================================
-- A subquery is a SELECT inside another SELECT.
-- The inner query runs first. Its result is used by the outer query.
-- CTEs are generally preferred for readability, but subqueries
-- are common in production code and important to recognise.
-- ================================================================


-- ================================================================
-- QUERY 1: Production Runs Above Overall Average Efficiency
-- ================================================================
-- BUSINESS QUESTION:
--   Which production runs performed better than the
--   company's average efficiency?
--
-- SUBQUERY TYPE:
--   Scalar Subquery
--   (returns a single value)
-- ================================================================

SELECT
    run_id,
    plant_id,
    product_id,
    run_date,
    shift,
    efficiency_pct

FROM manufacturing.production_runs

WHERE efficiency_pct >

(
    SELECT AVG(efficiency_pct)
    FROM manufacturing.production_runs
)

ORDER BY efficiency_pct DESC;


-- ================================================================
-- QUERY 2: Products With More Defects Than Average
-- ================================================================
-- BUSINESS QUESTION:
--   Which products have more failed quality samples than
--   the average product?
--
-- SUBQUERY TYPE:
--   Subquery in HAVING clause
-- ================================================================

SELECT
    product_id,

    SUM(failed) AS total_failed_samples

FROM manufacturing.quality_checks

GROUP BY product_id

HAVING SUM(failed) >

(
    SELECT AVG(product_failures)
    FROM
    (
        SELECT
            product_id,
            SUM(failed) AS product_failures
        FROM manufacturing.quality_checks
        GROUP BY product_id
    ) avg_failures
)

ORDER BY total_failed_samples DESC;


-- ================================================================
-- QUERY 3: Suppliers With Above-Average Material Spend
-- ================================================================
-- BUSINESS QUESTION:
--   Which suppliers account for higher-than-average
--   procurement costs?
--
-- SUBQUERY TYPE:
--   Derived Table Subquery
-- ================================================================

SELECT
    supplier_name,
    total_spend

FROM
(
    SELECT
        supplier_name,

        SUM(total_cost) AS total_spend

    FROM manufacturing.supply_chain

    GROUP BY supplier_name

) supplier_summary

WHERE total_spend >

(
    SELECT AVG(total_supplier_spend)
    FROM
    (
        SELECT
            supplier_name,
            SUM(total_cost) AS total_supplier_spend
        FROM manufacturing.supply_chain
        GROUP BY supplier_name
    ) supplier_avg
)

ORDER BY total_spend DESC;