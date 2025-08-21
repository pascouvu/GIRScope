-- export_table_definitions.sql
-- Produce readable DDL-like descriptions for all base tables in 'public' and 'auth' schemas.
-- Run in Supabase SQL editor or psql. The output is one row per table with a "ddl_text" column.

WITH tables_to_doc AS (
  SELECT table_schema, table_name
  FROM information_schema.tables
  WHERE table_schema IN ('public','auth')
    AND table_type = 'BASE TABLE'
  ORDER BY table_schema, table_name
)
SELECT
  t.table_schema,
  t.table_name,
  (
    '-- ------------------------------------------------------------' || E'\n'
    || '-- DDL summary for ' || t.table_schema || '.' || t.table_name || E'\n'
    || '-- ------------------------------------------------------------' || E'\n\n'
    || 'Columns:' || E'\n'
    || COALESCE(
         (
           SELECT string_agg('  ' || column_name || ' ' || column_type || ' ' || nullable || COALESCE(' DEFAULT '||column_default, ''), E'\n')
           FROM (
             SELECT column_name,
               CASE
                 WHEN character_maximum_length IS NOT NULL AND data_type IN ('character varying','character','varchar','char')
                   THEN data_type || '(' || character_maximum_length || ')'
                 WHEN data_type = 'numeric' AND numeric_precision IS NOT NULL
                   THEN data_type || '(' || numeric_precision || ',' || COALESCE(numeric_scale,0) || ')'
                 ELSE data_type
               END AS column_type,
               CASE WHEN is_nullable = 'NO' THEN 'NOT NULL' ELSE 'NULL' END AS nullable,
               column_default
             FROM information_schema.columns c
             WHERE c.table_schema = t.table_schema AND c.table_name = t.table_name
             ORDER BY ordinal_position
           ) cols
         ), '  (no columns)'
       )

    || E'\n\nConstraints:' || E'\n'
    || COALESCE(
         (
           SELECT string_agg('  ' || tc.constraint_type || ' ' || tc.constraint_name || ' : ' || pg_get_constraintdef(con.oid), E'\n')
           FROM information_schema.table_constraints tc
           JOIN pg_constraint con ON con.conname = tc.constraint_name
             AND con.connamespace = (SELECT oid FROM pg_namespace WHERE nspname = tc.constraint_schema)
           WHERE tc.table_schema = t.table_schema AND tc.table_name = t.table_name
         ), '  (no constraints)'
       )

    || E'\n\nIndexes:' || E'\n'
    || COALESCE(
         (
           SELECT string_agg('  ' || indexname || ' : ' || indexdef, E'\n')
           FROM pg_indexes p
           WHERE p.schemaname = t.table_schema AND p.tablename = t.table_name
         ), '  (no indexes)'
       )

    || E'\n\nPolicies:' || E'\n'
    || COALESCE(
         (
           SELECT string_agg(
             '  ' || pol.policyname
             || ' : roles=' || COALESCE(array_to_string(pol.roles, ','), '(none)')
             || ' qual=' || COALESCE(pol.qual::text, '(none)')
             || ' with_check=' || COALESCE(pol.with_check::text, '(none)')
             , E'\n')
           FROM pg_policies pol
           WHERE pol.schemaname = t.table_schema AND pol.tablename = t.table_name
         ), '  (no policies)'
       )
  ) AS ddl_text
FROM tables_to_doc t;

-- End of script

