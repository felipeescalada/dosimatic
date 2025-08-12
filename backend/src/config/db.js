const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER || 'secwin_user',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'secwin_db',
  password: process.env.DB_PASSWORD || 'secwin_password',
  port: process.env.DB_PORT || 5432,
});

module.exports = pool;
