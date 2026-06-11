

-- ================================================================
-- 02_aggregation.sql — GROUP BY and Aggregate Functions
-- ================================================================
-- Aggregation answers questions like:
--   "What is the average salary per department?"
--   "How many employees are in each city?"
--   "What is the total revenue by product category?"
--
-- AGGREGATE FUNCTIONS reduce many rows to one summary value:
--   COUNT(*)       → how many rows
--   COUNT(column)  → how many non-null values
--   SUM(column)    → total of all values
--   AVG(column)    → arithmetic average
--   MIN(column)    → smallest value
--   MAX(column)    → largest value
--   ROUND(n, d)    → round n to d decimal places
--
-- GROUP BY splits the table into groups before aggregating.
-- Without GROUP BY: one number for the entire table.
-- With GROUP BY: one number per group.
-- ================================================================


-- ================================================================
-- SECTION 1: Basic aggregation (no GROUP BY)
-- ================================================================

-- 1.1 — Count total plants
SELECT COUNT(*) AS total_plants
FROM manufacturing.plants p ;

-- 1.2 — Count only active employees
-- COUNT(*) counts all rows. COUNT(column) counts non-null values in that column.

SELECT
    COUNT(*) AS total_runs,
    COUNT(planned_units) AS runs_with_planned_units,
    COUNT(actual_units) AS runs_with_actual_units,
    COUNT(defective_units) AS runs_with_defect_data,
    COUNT(*) - COUNT(actual_units) AS runs_missing_actual_units,
    COUNT(*) - COUNT(defective_units) AS runs_missing_defect_data
FROM manufacturing.production_runs;



-- 1.3 — Company-wide production runs statistics

SELECT
    COUNT(*) AS total_runs,
    COUNT(actual_units) AS populated_actual_units,
    COUNT(*) - COUNT(actual_units) AS missing_actual_units,
    COUNT(defective_units) AS populated_defective_units,
    COUNT(*) - COUNT(defective_units) AS missing_defective_units,
    COUNT(efficiency_pct) AS populated_efficiency,
    COUNT(*) - COUNT(efficiency_pct) AS missing_efficiency
FROM manufacturing.production_runs;

-- ================================================================
-- SECTION 2: GROUP BY — aggregation per group
-- ================================================================

-- 2.1 — Headcount per department
-- GROUP BY splits employees into department groups.
-- COUNT(*) then counts rows within each group.

SELECT DISTINCT status
FROM manufacturing.supply_chain
order by status;

-- 2.2 — Salary statistics per department
SELECT
    COUNT(*) AS total_rows,
    COUNT(product_code) AS rows_with_product_code,
    COUNT(product_name) AS rows_with_product_name,
    COUNT(category) AS rows_with_category,
    COUNT(target_price) AS rows_with_target_price,
    COUNT(*) - COUNT(target_price) AS rows_missing_target_price
FROM manufacturing.products;

-- 2.3 — Multiple GROUP BY columns
-- Group by BOTH department AND performance_rating.
-- Result: one row per (department, performance_rating) combination.
-- This answers: "For each department, how many employees in each rating?"
SELECT
    department,
    performance_rating,
    COUNT(*) AS count
FROM bootcamp_data.employees
WHERE is_active = TRUE
GROUP BY department, performance_rating
ORDER BY department, count DESC;

SELECT
    plant_id,
    COUNT(*) AS total_runs,
    ROUND(AVG(efficiency_pct), 2) AS avg_efficiency
FROM manufacturing.production_runs
GROUP BY plant_id
ORDER BY avg_efficiency DESC
LIMIT 10;

-- 2.4 — GROUP BY with WHERE
-- WHERE filters BEFORE grouping.
-- Only active employees are included before the group calculation.
-- RULE: WHERE cannot reference aggregate functions — use HAVING for that.


SELECT
    supplier_name,
    COUNT(*) AS total_orders,
    ROUND(SUM(total_cost), 2) AS total_spend
FROM manufacturing.supply_chain
GROUP BY supplier_name
ORDER BY total_spend DESC
LIMIT 10;

-- ================================================================
-- SECTION 3: HAVING — filtering after aggregation
-- ================================================================
-- WHERE filters individual rows BEFORE grouping.
-- HAVING filters GROUPS AFTER grouping.
-- Rule: if your filter uses an aggregate function (COUNT, AVG, etc.)
--       you MUST use HAVING, not WHERE.
-- ================================================================

-- 3.1 — Departments with more than 50 employees
-- This cannot use WHERE because headcount is computed after grouping.

SELECT
    supplier_name,
    COUNT(*) AS total_orders,
    ROUND(SUM(total_cost), 2) AS total_spend
FROM manufacturing.supply_chain
GROUP BY supplier_name
HAVING SUM(total_cost) > 50000
ORDER BY total_spend DESC
LIMIT 10;

-- 3.2 — Inspectors Finding the Most Defects

SELECT
    inspector,
    COUNT(*) AS inspections,
    SUM(failed) AS total_failed_samples
FROM manufacturing.quality_checks
GROUP BY inspector
HAVING COUNT(*) >= 5
ORDER BY total_failed_samples DESC
LIMIT 5;

-- 3.3 — Combining WHERE and HAVING
-- Equipment with Lowest Efficiency
SELECT
    equipment_name,
    equipment_type,
    ROUND(AVG(efficiency_pct), 2) AS avg_efficiency
FROM manufacturing.equipment
GROUP BY
    equipment_name,
    equipment_type
HAVING AVG(efficiency_pct) < 85
ORDER BY avg_efficiency ASC
LIMIT 10;

-- ================================================================
-- SECTION 4: The SQL Execution Order
-- ================================================================
-- SQL does NOT execute in the order you write it.
-- The actual execution order is:
--   1. FROM        → identify the table(s)
--   2. WHERE       → filter rows
--   3. GROUP BY    → split into groups
--   4. HAVING      → filter groups
--   5. SELECT      → compute output columns
--   6. ORDER BY    → sort results
--   7. LIMIT       → restrict row count
--
-- This is why you cannot use an alias from SELECT in a WHERE clause —
-- WHERE runs BEFORE SELECT so the alias does not exist yet.
-- ================================================================

-- 4.1 — Plants with Highest Downtime

SELECT
    plant_id,
    SUM(downtime_mins) AS total_downtime
FROM manufacturing.production_runs
GROUP BY plant_id
HAVING SUM(downtime_mins) > 1000
ORDER BY total_downtime DESC
LIMIT 10;

