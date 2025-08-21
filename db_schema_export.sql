-- db_schema_export.sql
-- Purpose: Produce a human-readable export of table definitions, constraints,
-- indexes, RLS policies, functions and triggers for the 'public' and 'auth'
-- schemas. Run this in Supabase SQL editor or psql and save the result to a file.

-- Note: This script does not generate perfectly recreatable CREATE TABLE DDL
-- (use pg_dump -s for that). Instead it assembles a readable description
-- of each table useful for documentation and review.

-- 1) List of tables to document
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema IN ('public','auth')
  AND table_type = 'BASE TABLE'
ORDER BY table_schema, table_name;

-- 2) Column definitions per table
SELECT table_schema, table_name,
       column_name, data_type, is_nullable, column_default, character_maximum_length
FROM information_schema.columns
WHERE table_schema IN ('public','auth')
ORDER BY table_schema, table_name, ordinal_position;

-- 3) Primary keys and unique constraints
SELECT tc.table_schema, tc.table_name, tc.constraint_type, tc.constraint_name,
       kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema IN ('public','auth')
  AND tc.constraint_type IN ('PRIMARY KEY','UNIQUE')
ORDER BY tc.table_schema, tc.table_name, tc.constraint_type;

-- 4) Foreign keys
SELECT tc.table_schema, tc.table_name, kcu.column_name, ccu.table_schema AS foreign_table_schema,
       ccu.table_name AS foreign_table_name, ccu.column_name AS foreign_column_name, tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu
  ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_schema IN ('public','auth')
  AND tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.table_schema, tc.table_name;

-- 5) Indexes (public schema)
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname IN ('public')
ORDER BY schemaname, tablename, indexname;

-- 6) RLS status for tables
SELECT schemaname, tablename, rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname IN ('public','auth')
ORDER BY schemaname, tablename;

-- 7) RLS policies (if pg_policies view exists)
-- pg_policies is available in many managed Postgres setups (Supabase).
SELECT schemaname, tablename, policyname, permissive, roles, qual, with_check
FROM pg_policies
WHERE schemaname IN ('public','auth')
ORDER BY schemaname, tablename, policyname;

-- 8) Functions and procedures in public/auth schemas
SELECT routine_schema, routine_name, routine_type, data_type
FROM information_schema.routines
WHERE routine_schema IN ('public','auth')
ORDER BY routine_schema, routine_name;

-- 9) Triggers
SELECT event_object_schema, event_object_table, trigger_name, action_timing, action_statement
FROM information_schema.triggers
WHERE event_object_schema IN ('public','auth')
ORDER BY event_object_schema, event_object_table, trigger_name;

-- 10) Helpful sample rows per important table (limit to 5 rows)
-- Comment/uncomment tables that do not exist in your database
-- Businesses
SELECT 'businesses' AS source_table, * FROM public.businesses LIMIT 5;

-- Public users
SELECT 'public.users' AS source_table, id, email, full_name, business_id, role, created_at, updated_at
FROM public.users ORDER BY created_at DESC LIMIT 10;

-- Drivers
SELECT 'drivers' AS source_table, * FROM public.drivers LIMIT 5;

-- Vehicles
SELECT 'vehicles' AS source_table, * FROM public.vehicles LIMIT 5;

-- Fuel transactions
SELECT 'fuel_transactions' AS source_table, * FROM public.fuel_transactions LIMIT 5;

-- Products
SELECT 'products' AS source_table, * FROM public.products LIMIT 5;

-- Pumps
SELECT 'pumps' AS source_table, * FROM public.pumps LIMIT 5;

-- Vehicle products
SELECT 'vehicle_products' AS source_table, * FROM public.vehicle_products LIMIT 5;

-- Departments
SELECT 'departments' AS source_table, * FROM public.departments LIMIT 5;

-- Sites
SELECT 'sites' AS source_table, * FROM public.sites LIMIT 5;

-- 11) Table counts (approximate)
-- Use pg_stat_all_tables / pg_class for fast approximate row counts. For exact counts run
-- `SELECT count(*) FROM public.<table>;` per table when needed.
SELECT c.relname AS table_name,
       COALESCE(s.n_live_tup, c.reltuples::bigint) AS approx_row_count
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_stat_all_tables s ON s.relid = c.oid AND s.schemaname = 'public'
WHERE n.nspname = 'public'
  AND c.relkind = 'r'
ORDER BY c.relname;

-- Note: approx_row_count is an estimate maintained by PostgreSQL's statistics collector.

-- End of script

