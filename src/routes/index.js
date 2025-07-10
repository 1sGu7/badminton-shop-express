const express = require('express');
const authRoutes = require('./auth');
const adminRoutes = require('./admin');
const productRoutes = require('./products');

const router = express.Router();

router.use('/auth', authRoutes);
router.use('/admin', adminRoutes);
router.use('/products', productRoutes);

module.exports = router; 