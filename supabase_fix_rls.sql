-- Fix for RLS policies to allow writing to the departments table

-- Allow public role to INSERT into departments (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public insert for departments"
ON departments FOR INSERT
TO public
WITH CHECK (true);

-- Allow public role to UPDATE departments (TEMPORARY FOR DEVELOPMENT)
CREATE POLICY "Allow public update for departments"
ON departments FOR UPDATE
TO public
USING (true);
