# Multi-Company Migration Guide

## Overview

This guide walks you through migrating your existing single-business data to the new multi-company architecture. All existing data will be assigned to the PBT business.

## Prerequisites

1. ✅ Database schema updated with `business_id` columns (run `add_business_id_to_tables.sql`)
2. ✅ RLS policies created for business isolation
3. ✅ Application code updated for business context

## Migration Steps

### Step 1: Create the PBT Business

First, create the PBT business with the original API credentials:

```sql
-- Run: create_pbt_business.sql
```

This script will:
- Create the PBT business if it doesn't exist
- Use the original API credentials from `secret.dart`
- Set business code as 'PBT01'

### Step 2: Update Existing Data

Assign all existing data to the PBT business:

```sql
-- Run: update_existing_data_to_pbt_business.sql
```

This script will:
- Find the PBT business ID
- Update all tables to set `business_id = PBT_business_id`
- Show progress and verification queries

### Step 3: Verify the Migration

The migration script includes verification queries that will show:

1. **Record counts** for each table
2. **Business ID assignment** status
3. **Sample data** to verify the updates

## Expected Output

After running the migration, you should see output like:

```
NOTICE:  Found PBT business with ID: 12345678-1234-1234-1234-123456789abc
NOTICE:  Updated 150 vehicles with PBT business_id
NOTICE:  Updated 75 drivers with PBT business_id
NOTICE:  Updated 2500 fuel_transactions with PBT business_id
NOTICE:  Updated 25 products with PBT business_id
NOTICE:  Updated 10 sites with PBT business_id
NOTICE:  Updated 30 pumps with PBT business_id
NOTICE:  Updated 15 tanks with PBT business_id
NOTICE:  Updated 8 controllers with PBT business_id
NOTICE:  Updated 200 vehicle_products with PBT business_id
NOTICE:  Updated 12 departments with PBT business_id
NOTICE:  All existing data has been assigned to PBT business (ID: 12345678-1234-1234-1234-123456789abc)
```

## Verification Queries

After migration, you can run these queries to verify everything is working:

### 1. Check Business Assignment
```sql
-- Verify all records have business_id
SELECT 
    'vehicles' as table_name,
    COUNT(*) as total_records,
    COUNT(business_id) as records_with_business_id,
    CASE WHEN COUNT(*) = COUNT(business_id) THEN 'OK' ELSE 'MISSING' END as status
FROM vehicles
UNION ALL
SELECT 
    'drivers' as table_name,
    COUNT(*) as total_records,
    COUNT(business_id) as records_with_business_id,
    CASE WHEN COUNT(*) = COUNT(business_id) THEN 'OK' ELSE 'MISSING' END as status
FROM drivers
UNION ALL
SELECT 
    'fuel_transactions' as table_name,
    COUNT(*) as total_records,
    COUNT(business_id) as records_with_business_id,
    CASE WHEN COUNT(*) = COUNT(business_id) THEN 'OK' ELSE 'MISSING' END as status
FROM fuel_transactions;
```

### 2. Check PBT Business Data
```sql
-- Verify PBT business exists
SELECT 
    id,
    business_name,
    business_code,
    api_url,
    created_at
FROM businesses 
WHERE business_name = 'PBT';
```

### 3. Sample Data Verification
```sql
-- Check sample data has correct business_id
SELECT 
    'vehicles' as table_name,
    id,
    name,
    business_id
FROM vehicles 
WHERE business_id IS NOT NULL
LIMIT 3;
```

## Troubleshooting

### Issue: "Business with name 'PBT' not found"
**Solution:** Run `create_pbt_business.sql` first, then run the update script.

### Issue: Some records still have NULL business_id
**Solution:** Check if there are any constraints preventing the update. Run the verification queries to identify which tables have issues.

### Issue: RLS policies blocking access
**Solution:** Ensure users are assigned to the PBT business:
```sql
-- Update existing users to PBT business
UPDATE users 
SET business_id = (SELECT id FROM businesses WHERE business_name = 'PBT')
WHERE business_id IS NULL;
```

## Post-Migration Checklist

After running the migration:

1. ✅ **Verify all tables have business_id assigned**
2. ✅ **Test user login and data access**
3. ✅ **Verify RLS policies are working**
4. ✅ **Test API integration with business context**
5. ✅ **Verify sync functionality works**

## Rollback Plan

If you need to rollback the migration:

```sql
-- Remove business_id columns (WARNING: This will lose data isolation)
ALTER TABLE vehicles DROP COLUMN IF EXISTS business_id;
ALTER TABLE drivers DROP COLUMN IF EXISTS business_id;
ALTER TABLE fuel_transactions DROP COLUMN IF EXISTS business_id;
-- ... repeat for all tables
```

## Next Steps

After successful migration:

1. **Test the application** with the new multi-company structure
2. **Add new businesses** as needed
3. **Create users** for new businesses
4. **Monitor RLS policies** and data access

## Support

If you encounter issues during migration:

1. Check the verification queries output
2. Review the error messages in the migration script
3. Ensure all prerequisites are met
4. Verify database permissions

---

**Note:** This migration is designed to be safe and reversible. Always backup your database before running migration scripts.
