const express = require('express');
const Product = require('../models/Product');

const router = express.Router();

// Danh sách sản phẩm
router.get('/', async (req, res) => {
  const products = await Product.find().sort({ createdAt: -1 });
  res.render('products/list', { products, title: 'Sản phẩm cầu lông', userId: res.locals.userId });
});

// Chi tiết sản phẩm
router.get('/:id', async (req, res) => {
  const product = await Product.findById(req.params.id);
  if (!product) return res.redirect('/products');
  res.render('products/detail', { product, title: product.name, userId: res.locals.userId });
});

module.exports = router; 