-- ================================================================
-- 01_basics.sql — SQL Fundamentals
-- ================================================================
-- HOW TO USE THIS FILE:
--   Open in DBeaver. Read each section. Highlight a query.
--   Press Ctrl+Enter to run just that highlighted query.
--   Look at the results. Modify the query. Run again.
--   Learning SQL is about EXPERIMENTING — not memorising.
--
-- DATABASE: Supabase PostgreSQL
-- SCHEMA:   manufacturing  --- change this as per the manufacturing data 
-- TABLE:    equipment  --- change this as per the equipment data (1,000 rows of manufacturing equipment data)
-- TABLE:    plants  --- change this as per the plants data (100 rows of manufacturing plant data)  
-- TABLE:    production_runs  --- change this as per the production runs data (10,000 rows of production run data)
-- TABLE:    products  --- change this as per the products data (500 rows of product data)
-- TABLE:    quality_checks  --- change this as per the quality checks data (50,000 rows of quality check data)
-- TABLE:    supply_chain  --- change this as per the supply chain data (5,000 rows of supply chain data)
-- ================================================================
-- TABLE OF CONTENTS: 


-- ================================================================
-- SECTION 1: SELECT — The most important SQL keyword
-- ================================================================
-- SELECT tells PostgreSQL which COLUMNS you want.
-- FROM tells PostgreSQL which TABLE to read from.
-- Every SQL query starts with SELECT ... FROM ...
-- ================================================================

-- 1.1 — Select ALL columns (the asterisk * means "all columns")
-- Use this to see the full structure of a table for the first time.
-- CAUTION: Never use SELECT * in production — always name specific columns.
SELECT *
FROM manufacturing.equipment
LIMIT 10;   -- LIMIT restricts output to the first 10 rows (always use LIMIT when exploring!)

SELECT *
FROM manufacturing.plants
LIMIT 10;   -- LIMIT restricts output to the first 10 rows (always use LIMIT when exploring!)

SELECT *
FROM manufacturing.production_runs
LIMIT 10;   -- LIMIT restricts output to the first 10 rows (always use LIMIT when exploring!)

SELECT *
FROM manufacturing.products
LIMIT 10;   -- LIMIT restricts output to the first 10 rows (always use LIMIT when exploring!)

SELECT *
FROM manufacturing.quality_checks
LIMIT 10;   -- LIMIT restricts output to the first 10 rows (always use LIMIT when exploring!)   

SELECT *
FROM manufacturing.supply_chain
LIMIT 10;   -- LIMIT restricts output to the first 10 rows (always use LIMIT when exploring!)





-- 1.2 — Select SPECIFIC columns (best practice)
-- Only request the columns you actually need.
-- This is faster (less data transferred) and easier to read.
SELECT 
    plant_id,
	equipment_name,
	equipment_type,
	manufacturer,
	install_date,
	last_maintenance,
	next_maintenance,
	status,
	efficiency_pct
FROM manufacturing.equipment
LIMIT 10;


-- 1.3 — Column aliases with AS
-- AS renames a column in the output — does NOT change the original table.
-- Useful for making column names cleaner or more descriptive.

SELECT
	plant_name AS "Plant Name", 
	city       AS "In City",       
	country    AS "In Country",
	plant_type AS "Plant Type",
	capacity_units   AS "Manufacturing Capacity",
	employees_count  AS "Number of Employees",
	manager,
	opened_year,
	is_active
FROM manufacturing.plants p 
LIMIT 10;


-- 1.4 — DISTINCT — remove duplicate values
-- Returns only unique values in the specified column(s).
-- Like Python's list(set(values)) but much faster at scale.
SELECT DISTINCT plant_type
FROM manufacturing.plants p 
ORDER BY p.plant_type ;    -- ORDER BY sorts alphabetically (ASC by default)


-- ================================================================
-- SECTION 2: WHERE — Filtering rows
-- ================================================================
-- WHERE filters which ROWS appear in the result.
-- Only rows where the condition is TRUE are returned.
-- WHERE is always placed AFTER FROM and BEFORE ORDER BY.
-- ================================================================

-- 2.1 — Simple equality filter
-- Find all equipments manufactured by Bosch
SELECT 
	e.plant_id,
	e.equipment_name,
	e.equipment_type,
	e.manufacturer
FROM manufacturing.equipment e 
WHERE e.manufacturer  = 'Bosch';   -- text values use SINGLE quotes in SQL


-- 2.2 — Numeric comparison operators
-- >  (greater than)
-- >= (greater than or equal to)
-- <  (less than)
-- <= (less than or equal to)
-- =  (equal to)
-- <> or != (not equal to)
SELECT 
	sc.product_id,
	sc.supplier_name,
 	sc.material_name,
	sc.quantity,
	sc.unit,
 	sc.unit_cost,
	sc.total_cost,
	sc.status,
	sc.quality_grade
FROM manufacturing.supply_chain sc 
WHERE sc.quality_grade  = 'B'
ORDER BY sc.product_id  DESC;   -- DESC = descending (highest first), ASC = ascending (default)


-- 2.3 — AND: both conditions must be true
-- using products table Find those above 3000
SELECT 
	pd.product_id,
  	pd.product_code,
	pd.product_name,
	pd.category,
	pd.unit_cost,
	pd.target_price,
	pd.weight_kg,
	pd.lead_time_days,
	pd.is_active
FROM manufacturing.products pd 
WHERE pd.category  = 'Industrial'
  AND pd.unit_cost  > 3000
  AND is_active = TRUE;


-- 2.4 — OR: at least one condition must be true
-- Find employees in either Engineering or Data Science
SELECT 
	pd.product_id,
	pd.product_code,
	pd.product_name,
	pd.category,
	pd.unit_cost,
	pd.target_price,
	pd.weight_kg,
	pd.lead_time_days
	--pd.is_active	
FROM manufacturing.products pd 
WHERE pd.category = 'Consumer Goods'
   OR pd.category = 'Industrial'
ORDER BY pd.category, pd.unit_cost DESC;


-- 2.5 — IN: cleaner alternative to multiple OR conditions
-- Equivalent to WHERE department = 'A' OR department = 'B' OR department = 'C'
SELECT 
	sc.product_id,
	sc.supplier_name,
	sc.material_name,
	sc.order_date,
	sc.delivery_date,
	sc.status,
	sc.quality_grade
FROM manufacturing.supply_chain sc
WHERE sc.status IN ('Delivered', 'In Transit', 'Ordered')
ORDER BY sc.material_name , sc.status  DESC;


-- 2.6 — BETWEEN: range filter (inclusive on both ends)
-- BETWEEN low AND high → equivalent to col >= low AND col <= high
SELECT 
	pr.run_id,
	pr.plant_id,
	pr.product_id,
	pr.run_date,
	pr.shift,
	pr.planned_units,
	pr.actual_units,
	pr.defective_units,
	pr.efficiency_pct,
	pr.downtime_mins,
	pr.operator
FROM manufacturing.production_runs pr
WHERE pr.defective_units  BETWEEN 1 AND 20
  AND pr.shift  = 'Morning'
ORDER BY pr.plant_id ;


-- 2.7 — LIKE: pattern matching for text
-- %  matches any sequence of characters (like * in file search)
-- _  matches exactly one character
-- ILIKE is the case-insensitive version (PostgreSQL-specific)
SELECT 
	p.product_id,
	p.product_code,
	p.product_name,
	p.category,
	p.unit_cost,
	p.target_price,
	p.weight_kg,
	p.lead_time_days,
	p.is_active
FROM manufacturing.products p 
WHERE p.product_name  ILIKE '%Consumer Goods%'   --  contains "Consumer Goods" (case-insensitive)
LIMIT 10;


-- 2.8 — IS NULL and IS NOT NULL
-- NULL means "no value present" — NOT the same as 0 or empty string
-- You CANNOT use = NULL (this always returns nothing in SQL)
-- You MUST use IS NULL or IS NOT NULL

SELECT  DISTINCT  COUNT(*) AS operators
FROM manufacturing.production_runs pr 
WHERE pr.operator  IS NOT NULL;


-- ================================================================
-- SECTION 3: ORDER BY and LIMIT
-- ================================================================

-- 3.1 — ORDER BY: sort results
-- ASC  = ascending  (A→Z, 0→9) — this is the DEFAULT if you don't specify
-- DESC = descending (Z→A, 9→0)
SELECT 
	pl.plant_id,
	pl.plant_name,
	pl.city,
	pl.country,
	pl.plant_type,
	pl.capacity_units,
	pl.employees_count,
	pl.manager,
	pl.opened_year,
	pl.is_active
FROM manufacturing.plants pl 
WHERE pl.is_active = TRUE
ORDER BY pl.city  DESC;   -- highest salary first


-- 3.2 — Multiple sort columns
-- Sort by department A→Z, then within each department by salary highest first
SELECT 
	p.plant_id,
	p.plant_name,
	p.city,
	p.country,
	p.plant_type,
	p.capacity_units,
	p.employees_count,
	p.manager,
	p.opened_year,
	p.is_active
FROM manufacturing.plants p 
ORDER BY p.country  ASC, p.plant_type  DESC;


-- 3.3 — LIMIT and OFFSET — pagination
-- LIMIT restricts how many rows to return
-- OFFSET skips the first N rows (used for pagination in web apps)
-- "Give me rows 11-20" → LIMIT 10 OFFSET 10
SELECT 
	e.equipment_id,
	e.plant_id,
	e.equipment_name,
	e.equipment_type,
	e.manufacturer,
	e.install_date,
	e.last_maintenance,
	e.next_maintenance,
	e.status,
	e.efficiency_pct
FROM manufacturing.equipment e 
ORDER BY e.manufacturer  DESC
LIMIT 10        -- top 10 earners
OFFSET 0;       -- start from the beginning (page 1)

-- Page 2 (rows 11-20):

SELECT 
	e.equipment_id,
	e.plant_id,
	e.equipment_name,
	e.equipment_type,
	e.manufacturer,
	e.install_date,
	e.last_maintenance,
	e.next_maintenance,
	e.status,
	e.efficiency_pct
FROM manufacturing.equipment e 
ORDER BY e.manufacturer  DESC
LIMIT 10        -- top 10 earners
OFFSET 10;       -- -- skip the first 10 rows (page 2)

