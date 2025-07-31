-- Create a function to get vehicles by a list of IDs
CREATE OR REPLACE FUNCTION get_vehicles_by_ids(ids TEXT[])
RETURNS SETOF vehicles AS $$
  SELECT * FROM vehicles WHERE id = ANY(ids);
$$ LANGUAGE sql STABLE;

-- Create a function to get drivers by a list of IDs
CREATE OR REPLACE FUNCTION get_drivers_by_ids(ids TEXT[])
RETURNS SETOF drivers AS $$
  SELECT * FROM drivers WHERE id = ANY(ids);
$$ LANGUAGE sql STABLE;