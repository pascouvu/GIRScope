# Temporary Supabase Row Level Security (RLS) Policies for Development

**WARNING: These policies grant `INSERT` and `UPDATE` permissions to the `anon` role. This is INSECURE for production environments and should ONLY be used for development purposes.**

For production, data synchronization should be handled by a secure backend (e.g., Supabase Functions, a dedicated server) using the `service_role` key, which bypasses RLS.

---

```sql
-- Allow anon role to INSERT into fuel_transactions (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow anon insert for fuel_transactions"
ON fuel_transactions FOR INSERT
TO anon
WITH CHECK (true);

-- Allow anon role to UPDATE fuel_transactions (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow anon update for fuel_transactions"
ON fuel_transactions FOR UPDATE
TO anon
USING (true);

-- Allow anon role to INSERT into vehicles (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow anon insert for vehicles"
ON vehicles FOR INSERT
TO anon
WITH CHECK (true);

-- Allow anon role to UPDATE vehicles (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow anon update for vehicles"
ON vehicles FOR UPDATE
TO anon
USING (true);

-- Allow anon role to INSERT into drivers (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow anon insert for drivers"
ON drivers FOR INSERT
TO anon
WITH CHECK (true);

-- Allow anon role to UPDATE drivers (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow anon update for drivers"
ON drivers FOR UPDATE
TO anon
USING (true);

-- Allow anon role to INSERT into products (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow anon insert for products"
ON products FOR INSERT
TO anon
WITH CHECK (true);

-- Allow anon role to UPDATE products (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow anon update for products"
ON products FOR UPDATE
TO anon
USING (true);

-- Allow anon role to INSERT into vehicle_products (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow anon insert for vehicle_products"
ON vehicle_products FOR INSERT
TO anon
WITH CHECK (true);

-- Allow anon role to UPDATE vehicle_products (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow anon update for vehicle_products"
ON vehicle_products FOR UPDATE
TO anon
USING (true);

-- Allow anon role to INSERT into sites (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow anon insert for sites"
ON sites FOR INSERT
TO anon
WITH CHECK (true);

-- Allow anon role to UPDATE sites (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow anon update for sites"
ON sites FOR UPDATE
TO anon
USING (true);
```
