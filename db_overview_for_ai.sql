-- db_overview_for_ai.sql
-- Purpose: Collect database schema and sample data useful for an AI or reviewer to understand
-- How to run: paste into Supabase SQL editor or psql connected to the project database.
-- It prints schema info, tables, columns, constraints, RLS policies, functions, triggers,
-- and sample counts/rows for the application's important tables.

-- ------------------------------
-- Basic database info
-- ------------------------------
SELECT current_database() AS database_name, current_schema() AS current_schema, version() AS pg_version;

-- ------------------------------
-- Schemas and tables of interest
-- ------------------------------
SELECT nspname AS schema_name, relname AS table_name
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE relkind = 'r'
  AND n.nspname NOT IN ('pg_catalog','information_schema')
ORDER BY nspname, relname;

-- ------------------------------
-- Table column definitions (for public schema)
-- ------------------------------
SELECT table_name, column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;

-- ------------------------------
-- Primary keys, foreign keys and unique constraints (public schema)
-- ------------------------------
SELECT
  tc.constraint_type,
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS referenced_table,
  ccu.column_name AS referenced_column
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.constraint_column_usage ccu
  ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_schema = 'public'
  AND tc.constraint_type IN ('PRIMARY KEY','FOREIGN KEY','UNIQUE')
ORDER BY tc.table_name, tc.constraint_type;

-- ------------------------------
-- Indexes (public schema)
-- ------------------------------
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- ------------------------------
-- Row Level Security (RLS) status and policies
-- ------------------------------
SELECT schemaname, tablename, rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname IN ('public','auth')
  AND tablename IN (
    'users','drivers','vehicles','fuel_transactions','products','pumps','vehicle_products','departments','sites'
  )
ORDER BY schemaname, tablename;

-- Show policies (pg_policies is Postgres contrib view available in Supabase)
SELECT schemaname, tablename, policyname, permissive, roles, qual, with_check
FROM pg_policies
WHERE schemaname IN ('public','auth')
ORDER BY schemaname, tablename, policyname;

-- ------------------------------
-- Functions and triggers (auth and public)
-- ------------------------------
SELECT routine_schema, routine_name, data_type, routine_type
FROM information_schema.routines
WHERE routine_schema IN ('public','auth')
ORDER BY routine_schema, routine_name;

SELECT event_object_schema, event_object_table, trigger_name, action_timing, action_statement
FROM information_schema.triggers
WHERE event_object_schema IN ('public','auth')
ORDER BY event_object_schema, event_object_table, trigger_name;

-- ------------------------------
-- Roles and current settings relevant to RLS/triggers
-- ------------------------------
SELECT rolname, rolsuper, rolcreaterole, rolcreatedb, rolcanlogin FROM pg_roles ORDER BY rolname;

-- Check current_setting('role') if available
SELECT current_setting('role', true) AS current_role_setting;

-- ------------------------------
-- Application-specific tables: counts and few sample rows
-- ------------------------------
-- Replace or add tables as needed for your schema

-- List tables to sample (approximate row counts using planner statistics)
-- NOTE: exact counts (COUNT(*)) can be expensive on large tables; use the commented queries below if you need exact values.
SELECT c.relname AS table_name,
       COALESCE(s.n_live_tup, c.reltuples::bigint) AS approx_row_count
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_stat_all_tables s ON s.relid = c.oid AND s.schemaname = 'public'
WHERE n.nspname = 'public'
  AND c.relname IN (
    'businesses','users','drivers','vehicles','fuel_transactions','products','pumps','vehicle_products','departments','sites'
  )
ORDER BY c.relname;

-- If you require exact counts for a specific table, run:
-- SELECT count(*) FROM public.users;

-- For each of the important tables, show up to 5 rows and column names
-- Businesses
SELECT * FROM public.businesses LIMIT 5;

-- Users (public.users)
SELECT id, email, full_name, business_id, role, created_at, updated_at
FROM public.users ORDER BY created_at DESC LIMIT 10;

-- Drivers
SELECT * FROM public.drivers LIMIT 5;

-- Vehicles
SELECT * FROM public.vehicles LIMIT 5;

-- Fuel transactions
SELECT * FROM public.fuel_transactions LIMIT 5;

-- Products
SELECT * FROM public.products LIMIT 5;

-- Pumps
SELECT * FROM public.pumps LIMIT 5;

-- Vehicle products
SELECT * FROM public.vehicle_products LIMIT 5;

-- Departments
SELECT * FROM public.departments LIMIT 5;

-- Sites
SELECT * FROM public.sites LIMIT 5;

-- ------------------------------
-- Sample queries that are useful to understand multi-tenancy and RLS usage
-- ------------------------------
-- Show whether public.users.business_id contains NULLs
SELECT
  (SELECT count(*) FROM public.users) AS total_public_users,
  (SELECT count(*) FROM public.users WHERE business_id IS NULL) AS users_with_null_business_id;

-- Show how many rows exist per business in key tables
SELECT b.id as business_id, b.business_name,
  (SELECT count(*) FROM public.vehicles v WHERE v.business_id = b.id) AS vehicles_count,
  (SELECT count(*) FROM public.drivers d WHERE d.business_id = b.id) AS drivers_count,
  (SELECT count(*) FROM public.fuel_transactions f WHERE f.business_id = b.id) AS fuel_transactions_count
FROM public.businesses b
ORDER BY b.business_name;

-- ------------------------------
-- Notes / next steps
-- - If some tables do not exist in your schema, the SELECTs will error — comment them out or adjust table names.
-- - You can extend the sample rows part with additional tables or join examples (e.g., vehicles + drivers).
-- - This file is intended as a starting point for automated analysis or human review.


