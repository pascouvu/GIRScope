-- Create the 'departments' table
CREATE TABLE IF NOT EXISTS departments (
    id TEXT PRIMARY KEY,
    name TEXT
);

-- Create the 'vehicles' table
CREATE TABLE IF NOT EXISTS vehicles (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    badge TEXT,
    pubsn_badge TEXT,
    ctrl_badge TEXT,
    code TEXT,
    pin_code TEXT,
    model TEXT,
    department_id TEXT REFERENCES departments(id),
    department_name TEXT, -- Denormalized for easier access
    kmeter INTEGER,
    hmeter NUMERIC,
    notes TEXT
);

-- Create the 'drivers' table
CREATE TABLE IF NOT EXISTS drivers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    first_name TEXT,
    badge TEXT,
    pubsn_badge TEXT,
    ctrl_badge TEXT,
    code TEXT,
    pin_code TEXT,
    department_id TEXT REFERENCES departments(id),
    department_name TEXT, -- Denormalized for easier access
    activity_prompt BOOLEAN,
    nce_prompt BOOLEAN,
    notes TEXT
);

-- Create the 'products' table (for vtanks)
CREATE TABLE IF NOT EXISTS products (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    capacity NUMERIC -- Assuming product has a capacity
);

-- Create the 'vehicle_products' linking table for vtanks
CREATE TABLE IF NOT EXISTS vehicle_products (
    vehicle_id TEXT REFERENCES vehicles(id),
    product_id TEXT REFERENCES products(id),
    capacity NUMERIC, -- Capacity specific to this vehicle-product relationship
    PRIMARY KEY (vehicle_id, product_id)
);

-- Create the 'fuel_transactions' table (already being synced, but for completeness)
CREATE TABLE IF NOT EXISTS fuel_transactions (
    id TEXT PRIMARY KEY,
    transac_id TEXT,
    date TIMESTAMPTZ,
    vehicle_id TEXT REFERENCES vehicles(id),
    vehicle_name TEXT,
    driver_id TEXT REFERENCES drivers(id),
    driver_name TEXT,
    site_id TEXT, -- Assuming site also has an ID
    site_name TEXT,
    volume NUMERIC,
    kdelta NUMERIC,
    kcons NUMERIC,
    hcons NUMERIC,
    manual BOOLEAN,
    mtr_forced BOOLEAN,
    vol_max BOOLEAN,
    new_kmeter BOOLEAN,
    new_hmeter BOOLEAN,
    has_anomalies BOOLEAN,
    anomalies_json JSONB
);

-- Create the 'sites' table
CREATE TABLE IF NOT EXISTS sites (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    code TEXT,
    address TEXT,
    city TEXT,
    zip_code TEXT,
    country TEXT,
    latitude NUMERIC,
    longitude NUMERIC
);

-- Create the 'tanks' table
CREATE TABLE IF NOT EXISTS tanks (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    volume NUMERIC,
    site_id TEXT REFERENCES sites(id)
);

-- Create the 'pumps' table
CREATE TABLE IF NOT EXISTS pumps (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    site_id TEXT REFERENCES sites(id)
);

-- Create the 'controllers' table
CREATE TABLE IF NOT EXISTS controllers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    site_id TEXT REFERENCES sites(id)
);