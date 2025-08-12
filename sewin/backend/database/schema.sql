-- Create Countries table
CREATE TABLE countries (
    country_id SERIAL PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL,
    country_code VARCHAR(3) NOT NULL UNIQUE
);

-- Create Cities table with foreign key to Countries
CREATE TABLE cities (
    city_id SERIAL PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    country_id INTEGER NOT NULL REFERENCES countries(country_id),
    UNIQUE(city_name, country_id)
);

-- Create Contacts table with foreign keys to Cities and Countries
CREATE TABLE contacts (
    id_contact VARCHAR(36) PRIMARY KEY,  -- Using UUID format
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    business_name VARCHAR(200),
    email VARCHAR(255) NOT NULL UNIQUE,
    phone_number VARCHAR(20) NOT NULL,
    country_id INTEGER NOT NULL REFERENCES countries(country_id),
    city_id INTEGER NOT NULL REFERENCES cities(city_id),
    zip_code VARCHAR(20),
    front_part_url TEXT,
    back_part_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status INTEGER DEFAULT 1 -- 1: Active, 0: Inactive
);

-- Insert sample countries
INSERT INTO countries (country_name, country_code) VALUES
('United States', 'USA'),
('Mexico', 'MEX'),
('Canada', 'CAN'),
('Colombia', 'COL'),
('Spain', 'ESP'),
('Argentina', 'ARG'),
('Chile', 'CHL'),
('Peru', 'PER'),
('Brazil', 'BRA'),
('Ecuador', 'ECU');

-- Insert sample cities
INSERT INTO cities (city_name, country_id) VALUES
-- United States cities
('New York', (SELECT country_id FROM countries WHERE country_code = 'USA')),
('Los Angeles', (SELECT country_id FROM countries WHERE country_code = 'USA')),
('Chicago', (SELECT country_id FROM countries WHERE country_code = 'USA')),
('Miami', (SELECT country_id FROM countries WHERE country_code = 'USA')),

-- Mexico cities
('Mexico City', (SELECT country_id FROM countries WHERE country_code = 'MEX')),
('Guadalajara', (SELECT country_id FROM countries WHERE country_code = 'MEX')),
('Monterrey', (SELECT country_id FROM countries WHERE country_code = 'MEX')),

-- Colombia cities
('Bogota', (SELECT country_id FROM countries WHERE country_code = 'COL')),
('Medellin', (SELECT country_id FROM countries WHERE country_code = 'COL')),
('Cali', (SELECT country_id FROM countries WHERE country_code = 'COL')),
('Barranquilla', (SELECT country_id FROM countries WHERE country_code = 'COL')),

-- Spain cities
('Madrid', (SELECT country_id FROM countries WHERE country_code = 'ESP')),
('Barcelona', (SELECT country_id FROM countries WHERE country_code = 'ESP')),
('Valencia', (SELECT country_id FROM countries WHERE country_code = 'ESP')),

-- Argentina cities
('Buenos Aires', (SELECT country_id FROM countries WHERE country_code = 'ARG')),
('Cordoba', (SELECT country_id FROM countries WHERE country_code = 'ARG')),
('Rosario', (SELECT country_id FROM countries WHERE country_code = 'ARG'));

-- Create indexes for better performance
CREATE INDEX idx_contacts_country ON contacts(country_id);
CREATE INDEX idx_contacts_city ON contacts(city_id);
CREATE INDEX idx_contacts_email ON contacts(email);
CREATE INDEX idx_contacts_status ON contacts(status);
CREATE INDEX idx_cities_country ON cities(country_id);

-- Example of how to insert a contact (commented out)
/*
INSERT INTO contacts (
    id_contact,
    first_name,
    last_name,
    business_name,
    email,
    phone_number,
    country_id,
    city_id,
    zip_code,
    front_part_url,
    back_part_url,
    status
) VALUES (
    'uuid-generated-value',
    'John',
    'Doe',
    'ACME Corp',
    'john.doe@example.com',
    '+1234567890',
    (SELECT country_id FROM countries WHERE country_code = 'USA'),
    (SELECT city_id FROM cities WHERE city_name = 'New York' AND country_id = (SELECT country_id FROM countries WHERE country_code = 'USA')),
    '10001',
    'https://example.com/front.jpg',
    'https://example.com/back.jpg',
    1
);
*/
