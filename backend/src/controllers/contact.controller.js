const contactModel = require('../models/contact.model');

const createContact = async (req, res) => {
    try {
        const contact = await contactModel.createContact(req.body);
        res.status(201).json({
            success: true,
            data: contact
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

const getContacts = async (req, res) => {
    try {
        const { page = 1, limit = 10, search, status } = req.query;
        const result = await contactModel.getContacts(
            parseInt(page),
            parseInt(limit),
            search,
            status !== undefined ? parseInt(status) : null
        );

        res.json({
            success: true,
            data: result.contacts,
            total: result.total,
            pages: result.pages,
            currentPage: result.currentPage
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

const getContactById = async (req, res) => {
    try {
        const contact = await contactModel.getContactById(req.params.id);
        if (!contact) {
            return res.status(404).json({
                success: false,
                message: 'Contact not found'
            });
        }
        res.json({
            success: true,
            data: contact
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

const updateContact = async (req, res) => {
    try {
        const contact = await contactModel.updateContact(req.params.id, req.body);
        if (!contact) {
            return res.status(404).json({
                success: false,
                message: 'Contact not found'
            });
        }

        res.json({
            success: true,
            data: contact
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

const deleteContact = async (req, res) => {
    try {
        const contact = await contactModel.deleteContact(req.params.id);
        if (!contact) {
            return res.status(404).json({
                success: false,
                message: 'Contact not found'
            });
        }

        res.json({
            success: true,
            message: 'Contact deleted successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

module.exports = {
    createContact,
    getContacts,
    getContactById,
    updateContact,
    deleteContact
};
