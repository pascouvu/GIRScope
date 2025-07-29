# Temporary Supabase Row Level Security (RLS) Policies for Public Role (Development)

**WARNING: These policies grant `INSERT` and `UPDATE` permissions to the `public` role. This is INSECURE for production environments and should ONLY be used for development purposes.**

For production, data synchronization should be handled by a secure backend (e.g., Supabase Functions, a dedicated server) using the `service_role` key, which bypasses RLS.

---

```sql
-- Enable RLS for all tables (if not already enabled)
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE fuel_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE tanks ENABLE ROW LEVEL SECURITY;
ALTER TABLE pumps ENABLE ROW LEVEL SECURITY;
ALTER TABLE controllers ENABLE ROW LEVEL SECURITY;

-- Policy for 'departments': Allow public role to read all departments
CREATE POLICY "Allow public read for departments"
ON departments FOR SELECT
TO public
USING (true);

-- Policy for 'vehicles': Allow public role to read all vehicles
CREATE POLICY "Allow public read for vehicles"
ON vehicles FOR SELECT
TO public
USING (true);

-- Policy for 'drivers': Allow public role to read all drivers
CREATE POLICY "Allow public read for drivers"
ON drivers FOR SELECT
TO public
USING (true);

-- Policy for 'products': Allow public role to read all products
CREATE POLICY "Allow public read for products"
ON products FOR SELECT
TO public
USING (true);

-- Policy for 'vehicle_products': Allow public role to read all vehicle_products
CREATE POLICY "Allow public read for vehicle_products"
ON vehicle_products FOR SELECT
TO public
USING (true);

-- Policy for 'fuel_transactions': Allow public role to read all fuel transactions
CREATE POLICY "Allow public read for fuel_transactions"
ON fuel_transactions FOR SELECT
TO public
USING (true);

-- Policy for 'sites': Allow public role to read all sites
CREATE POLICY "Allow public read for sites"
ON sites FOR SELECT
TO public
USING (true);

-- Policy for 'tanks': Allow public role to read all tanks
CREATE POLICY "Allow public read for tanks"
ON tanks FOR SELECT
TO public
USING (true);

-- Policy for 'pumps': Allow public role to read all pumps
CREATE POLICY "Allow public read for pumps"
ON pumps FOR SELECT
TO public
USING (true);

-- Policy for 'controllers': Allow public role to read all controllers
CREATE POLICY "Allow public read for controllers"
ON controllers FOR SELECT
TO public
USING (true);


-- TEMPORARY POLICIES FOR DEVELOPMENT (GRANTING WRITE ACCESS TO PUBLIC)
-- WARNING: These policies are INSECURE for production environments.

-- Allow public role to INSERT into fuel_transactions (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public insert for fuel_transactions"
ON fuel_transactions FOR INSERT
TO public
WITH CHECK (true);

-- Allow public role to UPDATE fuel_transactions (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public update for fuel_transactions"
ON fuel_transactions FOR UPDATE
TO public
USING (true);

-- Allow public role to INSERT into vehicles (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public insert for vehicles"
ON vehicles FOR INSERT
TO public
WITH CHECK (true);

-- Allow public role to UPDATE vehicles (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public update for vehicles"
ON vehicles FOR UPDATE
TO public
USING (true);

-- Allow public role to INSERT into drivers (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public insert for drivers"
ON drivers FOR INSERT
TO public
WITH CHECK (true);

-- Allow public role to UPDATE drivers (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public update for drivers"
ON drivers FOR UPDATE
TO public
USING (true);

-- Allow public role to INSERT into products (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public insert for products"
ON products FOR INSERT
TO public
WITH CHECK (true);

-- Allow public role to UPDATE products (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public update for products"
ON products FOR UPDATE
TO public
USING (true);

-- Allow public role to INSERT into vehicle_products (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public insert for vehicle_products"
ON vehicle_products FOR INSERT
TO public
WITH CHECK (true);

-- Allow public role to UPDATE vehicle_products (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public update for vehicle_products"
ON vehicle_products FOR UPDATE
TO public
USING (true);

-- Allow public role to INSERT into sites (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public insert for sites"
ON sites FOR INSERT
TO public
WITH CHECK (true);

-- Allow public role to UPDATE sites (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public update for sites"
ON sites FOR UPDATE
TO public
USING (true);

-- Allow public role to INSERT into tanks (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public insert for tanks"
ON tanks FOR INSERT
TO public
WITH CHECK (true);

-- Allow public role to UPDATE tanks (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public update for tanks"
ON tanks FOR UPDATE
TO public
USING (true);

-- Allow public role to INSERT into pumps (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public insert for pumps"
ON pumps FOR INSERT
TO public
WITH CHECK (true);

-- Allow public role to UPDATE pumps (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public update for pumps"
ON pumps FOR UPDATE
TO public
USING (true);

-- Allow public role to INSERT into controllers (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public insert for controllers"
ON controllers FOR INSERT
TO public
WITH CHECK (true);

-- Allow public role to UPDATE controllers (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public update for controllers"
ON controllers FOR UPDATE
TO public
USING (true);
```
