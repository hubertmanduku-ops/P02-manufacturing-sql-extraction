# ================================================================
# src/query_runner.py
# ================================================================
# CONTEXT:
#   We wrote SQL in .sql files. Now we need to EXECUTE those queries
#   from Python and get back pandas DataFrames we can work with.
#
# THE ANALOGY:
#   Think of SQLQueryRunner as a translator.
#   You hand it a SQL query (a string).
#   It sends that query to PostgreSQL.
#   PostgreSQL sends back rows of data.
#   SQLQueryRunner catches those rows and packages them as a DataFrame.
#
# KEY pandas FUNCTION: pd.read_sql()
#   pd.read_sql(sql_string, engine) executes SQL and returns a DataFrame.
#   This is what powers every Python + database workflow.
#
# WHY A CLASS AND NOT JUST pd.read_sql() DIRECTLY?
#   The class adds:
#     - Error handling (what if the query fails?)
#     - Logging (track what ran and when)
#     - Timing (how long did each query take?)
#     - Query loading from .sql files
#   These extras make it production-grade rather than just a script.
# ================================================================

import sys, pathlib, time

_root = pathlib.Path(__file__).resolve().parent
while not (_root / "config.py").exists() and _root != _root.parent:
    _root = _root.parent
if str(_root) not in sys.path:
    sys.path.insert(0, str(_root))

import pandas as pd
from config import engine, DB_AVAILABLE, SQL_DIR, INDUSTRY, logger


class SQLQueryRunner:
    """
    Executes SQL queries against the Supabase PostgreSQL database.
    Returns results as pandas DataFrames.

    Attributes
    ──────────
    industry   str           the configured industry schema
    history    list[dict]    log of every query run (for auditing)
    """

    def __init__(self):
        self.industry = INDUSTRY
        self.history  = []   # audit log: each entry records a query run
        logger.info(f"SQLQueryRunner ready — db_available: {DB_AVAILABLE}")

    def run(self, sql: str, params: dict = None) -> pd.DataFrame:
        """
        Execute a SQL query and return results as a DataFrame.

        Args:
            sql     the SQL query string to execute
            params  optional dict of parameters for parameterised queries
                    e.g. params={"dept": "Engineering"}
                    used as WHERE department = :dept in the SQL

        Returns:
            pd.DataFrame with query results (empty DataFrame if query fails)
        """
        if not DB_AVAILABLE or engine is None:
            logger.warning("[SQL] Database not available. Returning empty DataFrame.")
            return pd.DataFrame()

        # Replace {industry} placeholder with the actual schema name
        # This makes SQL files reusable across different industries
        sql = sql.replace("{industry}", self.industry)

        start_time = time.time()   # record start time for performance logging

        try:
            # pd.read_sql() executes SQL and returns a DataFrame
            # params → passed as bind parameters to prevent SQL injection
            df = pd.read_sql(sql, engine, params=params)

            duration_ms = round((time.time() - start_time) * 1000, 1)

            # Record this query in the history log
            self.history.append({
                "sql_preview": sql[:80].strip(),   # first 80 chars for the log
                "rows":        len(df),
                "cols":        len(df.columns),
                "duration_ms": duration_ms,
                "status":      "success",
            })

            logger.info(
                f"[SQL] Query complete — "
                f"{len(df):,} rows × {len(df.columns)} cols | "
                f"{duration_ms}ms"
            )

            return df

        except Exception as e:
            self.history.append({
                "sql_preview": sql[:80].strip(),
                "rows":        0,
                "cols":        0,
                "duration_ms": round((time.time() - start_time) * 1000, 1),
                "status":      f"error: {str(e)[:100]}",
            })
            logger.error(f"[SQL] Query failed: {e}")
            return pd.DataFrame()   # return empty DataFrame so callers do not crash

    def run_file(self, filename: str) -> pd.DataFrame:
        """
        Load a .sql file and execute it.

        Args:
            filename   name of the SQL file in the sql/ directory
                       e.g. "01_basics.sql" or "05_extract_raw_data.sql"

        Returns:
            pd.DataFrame with results of the LAST query in the file.
        """
        sql_path = SQL_DIR / filename

        if not sql_path.exists():
            logger.error(f"[SQL] File not found: {sql_path}")
            return pd.DataFrame()

        logger.info(f"[SQL] Loading: {filename}")

        # Read the .sql file as a Python string
        sql_text = sql_path.read_text(encoding="utf-8")

        # Run the SQL (may contain multiple statements separated by semicolons)
        # We run the whole file and return the result of the last statement
        return self.run(sql_text)

    def demo_basics(self) -> None:
        """
        Run selected demonstration queries from 01_basics.sql.
        Used during the teaching session to show SQL concepts live.
        """
             
        demos = [
            ("DISTINCT category",
             f"SELECT DISTINCT category FROM {self.industry}.products ORDER BY category"),

            ("Production Unit cost over 4000 and plant_type is Industrial",
             f"SELECT product_id, product_code, product_name, category, unit_cost FROM {self.industry}.products WHERE unit_cost > 4000 ORDER BY unit_cost DESC LIMIT 20"),

            ("Quality grade of 'A' in delivered, In transit and Odered products",
             f"SELECT product_id, supplier_name, material_name, order_date, delivery_date, status FROM {self.industry}.supply_chain WHERE status IN ('Delivered', 'In Transit', 'Ordered') AND quality_grade = 'A' ORDER BY status DESC LIMIT 20"),
        ]

        for title, sql in demos:
            print(f"\n── {title}:")
            df = self.run(sql)
            if not df.empty:
                print(df.to_string(index=False))

    def demo_aggregation(self) -> None:
        """Demo groupby queries from 02_aggregation.sql."""
        
        sql = f"""
            SELECT
                qc.defect_type,
                COUNT(*) AS defect_count,ROUND(AVG(pr.efficiency_pct),2) AS avg_efficiency
            FROM {self.industry}.quality_checks qc
            INNER JOIN {self.industry}.production_runs pr
				ON qc.run_id = pr.run_id
			GROUP BY qc.defect_type
			ORDER BY defect_count DESC;            
        """
        print("\n── --- Equipment defect and efficiency analysis ---:")
        df = self.run(sql)
        if not df.empty:
            print(df.to_string(index=False))

    def demo_joins(self) -> None:
        """Demo join query from 03_joins.sql."""
        sql = f"""
            SELECT
                e.equipment_name,
                COUNT(pr.run_id) AS production_runs,
                SUM(pr.downtime_mins) AS total_downtime,
                ROUND(AVG(pr.downtime_mins), 2) AS avg_downtime
            FROM {self.industry}.equipment e
            INNER JOIN {self.industry}.production_runs pr ON e.plant_id = pr.plant_id
            GROUP BY e.equipment_name
            ORDER BY total_downtime DESC
            LIMIT 20;
        """    
        
        print("\n── Equipment downtime analysis:")
        df = self.run(sql)
        if not df.empty:
            print(df.to_string(index=False))

    def __str__(self) -> str:
        return (f"SQLQueryRunner(industry={self.industry!r}, "
                f"queries_run={len(self.history)})")

    def __repr__(self) -> str:
        return f"SQLQueryRunner(industry={self.industry!r})"
