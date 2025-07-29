# Supabase Row Level Security (RLS) Policies

This file contains SQL commands to enable Row Level Security (RLS) on your Supabase tables and define basic `SELECT` policies. These policies ensure that only authenticated users can read data from these tables.

**Important Security Note:**
*   These policies are for `SELECT` (read) operations only.
*   `INSERT`, `UPDATE`, and `DELETE` operations should be handled with more restrictive policies or via the `service_role` key on your backend/server-side functions.
*   The `service_role` key bypasses RLS and should **never** be exposed in client-side code.

---

```sql
-- Enable RLS for all tables
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE fuel_transactions ENABLE ROW LEVEL SECURITY;

-- Policy for 'departments': Allow authenticated users to read all departments
CREATE POLICY "Allow authenticated read for departments"
ON departments FOR SELECT
TO authenticated
USING (true);

-- Policy for 'vehicles': Allow authenticated users to read all vehicles
CREATE POLICY "Allow authenticated read for vehicles"
ON vehicles FOR SELECT
TO authenticated
USING (true);

-- Policy for 'drivers': Allow authenticated users to read all drivers
CREATE POLICY "Allow authenticated read for drivers"
ON drivers FOR SELECT
TO authenticated
USING (true);

-- Policy for 'products': Allow authenticated users to read all products
CREATE POLICY "Allow authenticated read for products"
ON products FOR SELECT
TO authenticated
USING (true);

-- Policy for 'vehicle_products': Allow authenticated users to read all vehicle_products
CREATE POLICY "Allow authenticated read for vehicle_products"
ON vehicle_products FOR SELECT
TO authenticated
USING (true);

-- Policy for 'fuel_transactions': Allow authenticated users to read all fuel transactions
-- IMPORTANT: Write operations for fuel_transactions should ONLY be done via the service_role key
-- or secure backend functions, NOT directly from the client with the anon key.
CREATE POLICY "Allow authenticated read for fuel_transactions"
ON fuel_transactions FOR SELECT
TO authenticated
USING (true);
```
