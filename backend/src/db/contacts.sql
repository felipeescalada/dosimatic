CREATE TABLE IF NOT EXISTS contacts (
    id_contact UUID PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    business_name VARCHAR(200),
    email VARCHAR(255) NOT NULL UNIQUE,
    phone_number VARCHAR(50) NOT NULL,
    country_id INTEGER NOT NULL REFERENCES countries(country_id),
    city_id INTEGER NOT NULL REFERENCES cities(city_id),
    zip_code VARCHAR(20),
    front_part_url TEXT,
    back_part_url TEXT,
    status INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
