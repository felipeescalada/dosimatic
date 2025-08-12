const pool = require('../config/db');
const { v4: uuidv4 } = require('uuid');

const createContact = async (contactData) => {
    const {
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
        status = 1
    } = contactData;

    const id_contact = uuidv4();
    
    const result = await pool.query(
        `INSERT INTO contacts (
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
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) 
        RETURNING *`,
        [
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
        ]
    );

    return result.rows[0];
};

const getContacts = async (page = 1, limit = 10, search = '', status = null) => {
    const offset = (page - 1) * limit;
    let query = 'SELECT * FROM contacts WHERE 1=1';
    const values = [];
    let valueIndex = 1;

    if (status !== null) {
        query += ` AND status = $${valueIndex}`;
        values.push(status);
        valueIndex++;
    }

    if (search) {
        query += ` AND (
            first_name ILIKE $${valueIndex} OR 
            last_name ILIKE $${valueIndex} OR 
            email ILIKE $${valueIndex} OR 
            business_name ILIKE $${valueIndex}
        )`;
        values.push(`%${search}%`);
        valueIndex++;
    }

    query += ` ORDER BY created_at DESC`;
    if (limit > 0) {
        query += ` LIMIT $${valueIndex} OFFSET $${valueIndex + 1}`;
        values.push(limit, offset);
    }

    const result = await pool.query(query, values);
    const countResult = await pool.query('SELECT COUNT(*) FROM contacts');
    
    return {
        contacts: result.rows,
        total: parseInt(countResult.rows[0].count),
        pages: Math.ceil(parseInt(countResult.rows[0].count) / limit),
        currentPage: page
    };
};

const getContactById = async (id) => {
    const result = await pool.query(
        'SELECT * FROM contacts WHERE id_contact = $1',
        [id]
    );
    return result.rows[0];
};

const updateContact = async (id, contactData) => {
    const {
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
    } = contactData;

    const result = await pool.query(
        `UPDATE contacts 
        SET first_name = COALESCE($1, first_name),
            last_name = COALESCE($2, last_name),
            business_name = COALESCE($3, business_name),
            email = COALESCE($4, email),
            phone_number = COALESCE($5, phone_number),
            country_id = COALESCE($6, country_id),
            city_id = COALESCE($7, city_id),
            zip_code = COALESCE($8, zip_code),
            front_part_url = COALESCE($9, front_part_url),
            back_part_url = COALESCE($10, back_part_url),
            status = COALESCE($11, status)
        WHERE id_contact = $12
        RETURNING *`,
        [
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
            status,
            id
        ]
    );

    return result.rows[0];
};

const deleteContact = async (id) => {
    const result = await pool.query(
        'UPDATE contacts SET status = 0 WHERE id_contact = $1 RETURNING *',
        [id]
    );
    return result.rows[0];
};

module.exports = {
    createContact,
    getContacts,
    getContactById,
    updateContact,
    deleteContact
};
