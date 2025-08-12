const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const {
    createContact,
    getContacts,
    getContactById,
    updateContact,
    deleteContact
} = require('../controllers/contact.controller');

/**
 * @swagger
 * components:
 *   schemas:
 *     Contact:
 *       type: object
 *       required:
 *         - first_name
 *         - last_name
 *         - email
 *         - phone_number
 *         - country_id
 *         - city_id
 *       properties:
 *         id_contact:
 *           type: string
 *           format: uuid
 *           description: Auto-generated contact ID
 *         first_name:
 *           type: string
 *           description: Contact's first name
 *         last_name:
 *           type: string
 *           description: Contact's last name
 *         business_name:
 *           type: string
 *           description: Contact's business name
 *         email:
 *           type: string
 *           format: email
 *           description: Contact's email address
 *         phone_number:
 *           type: string
 *           description: Contact's phone number
 *         country_id:
 *           type: integer
 *           description: ID of the country
 *         city_id:
 *           type: integer
 *           description: ID of the city
 *         zip_code:
 *           type: string
 *           description: Contact's ZIP code
 *         front_part_url:
 *           type: string
 *           format: uri
 *           description: URL to front part image
 *         back_part_url:
 *           type: string
 *           format: uri
 *           description: URL to back part image
 *         status:
 *           type: integer
 *           description: Contact status (1 = active, 0 = deleted)
 *         created_at:
 *           type: string
 *           format: date-time
 *         updated_at:
 *           type: string
 *           format: date-time
 */

/**
 * @swagger
 * /api/contacts:
 *   post:
 *     summary: Create a new contact
 *     tags: [Contacts]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Contact'
 *     responses:
 *       201:
 *         description: Contact created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   $ref: '#/components/schemas/Contact'
 *       400:
 *         description: Invalid input data
 *       401:
 *         description: Unauthorized - Invalid or missing token
 */
router.post('/', verifyToken, createContact);

/**
 * @swagger
 * /api/contacts:
 *   get:
 *     summary: Get all contacts with pagination and filters
 *     tags: [Contacts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *         description: Number of items per page
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search term for filtering contacts
 *       - in: query
 *         name: status
 *         schema:
 *           type: integer
 *           enum: [0, 1]
 *         description: Filter by status (0 = deleted, 1 = active)
 *     responses:
 *       200:
 *         description: List of contacts
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Contact'
 *                 total:
 *                   type: integer
 *                 pages:
 *                   type: integer
 *                 currentPage:
 *                   type: integer
 *       401:
 *         description: Unauthorized - Invalid or missing token
 */
router.get('/', verifyToken, getContacts);

/**
 * @swagger
 * /api/contacts/{id}:
 *   get:
 *     summary: Get a contact by ID
 *     tags: [Contacts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *           format: uuid
 *         required: true
 *         description: Contact ID
 *     responses:
 *       200:
 *         description: Contact found
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   $ref: '#/components/schemas/Contact'
 *       404:
 *         description: Contact not found
 *       401:
 *         description: Unauthorized - Invalid or missing token
 */
router.get('/:id', verifyToken, getContactById);

/**
 * @swagger
 * /api/contacts/{id}:
 *   put:
 *     summary: Update a contact
 *     tags: [Contacts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *           format: uuid
 *         required: true
 *         description: Contact ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Contact'
 *     responses:
 *       200:
 *         description: Contact updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   $ref: '#/components/schemas/Contact'
 *       404:
 *         description: Contact not found
 *       401:
 *         description: Unauthorized - Invalid or missing token
 */
router.put('/:id', verifyToken, updateContact);

/**
 * @swagger
 * /api/contacts/{id}:
 *   delete:
 *     summary: Soft delete a contact
 *     tags: [Contacts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *           format: uuid
 *         required: true
 *         description: Contact ID
 *     responses:
 *       200:
 *         description: Contact deleted successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *       404:
 *         description: Contact not found
 *       401:
 *         description: Unauthorized - Invalid or missing token
 */
router.delete('/:id', verifyToken, deleteContact);

module.exports = router;
