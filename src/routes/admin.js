const express = require('express');
const Product = require('../models/Product');
const requireLogin = require('../middlewares/auth');
const { body, validationResult } = require('express-validator');
const multer = require('multer');
const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

const storage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: 'badminton-shop',
    allowed_formats: ['jpg', 'jpeg', 'png'],
  },
});
const upload = multer({ storage });

const router = express.Router();

// Danh sách sản phẩm
router.get('/products', requireLogin, async (req, res) => {
  const products = await Product.find().sort({ createdAt: -1 });
  res.render('admin/products', { products, title: 'Quản lý sản phẩm', userId: res.locals.userId });
});

// Form thêm sản phẩm
router.get('/products/new', requireLogin, (req, res) => {
  res.render('admin/new-product', { title: 'Thêm sản phẩm', userId: res.locals.userId });
});

// Thêm sản phẩm
router.post('/products', requireLogin, upload.single('image'),
  body('name').notEmpty(),
  body('description').notEmpty(),
  body('price').isNumeric(),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.cookie('error', 'Vui lòng nhập đủ thông tin');
      return res.redirect('/admin/products/new');
    }
    try {
      const { name, description, price } = req.body;
      const imageUrl = req.file.path;
      await Product.create({ name, description, price, imageUrl });
      res.cookie('success', 'Đã thêm sản phẩm');
      res.redirect('/admin/products');
    } catch (err) {
      res.cookie('error', 'Lỗi thêm sản phẩm');
      res.redirect('/admin/products/new');
    }
  });

// Form sửa sản phẩm
router.get('/products/:id/edit', requireLogin, async (req, res) => {
  const product = await Product.findById(req.params.id);
  if (!product) return res.redirect('/admin/products');
  res.render('admin/edit-product', { product, title: 'Sửa sản phẩm', userId: res.locals.userId });
});

// Sửa sản phẩm
router.post('/products/:id', requireLogin, upload.single('image'),
  body('name').notEmpty(),
  body('description').notEmpty(),
  body('price').isNumeric(),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.cookie('error', 'Vui lòng nhập đủ thông tin');
      return res.redirect(`/admin/products/${req.params.id}/edit`);
    }
    try {
      const { name, description, price } = req.body;
      const update = { name, description, price };
      if (req.file) update.imageUrl = req.file.path;
      await Product.findByIdAndUpdate(req.params.id, update);
      res.cookie('success', 'Đã cập nhật sản phẩm');
      res.redirect('/admin/products');
    } catch (err) {
      res.cookie('error', 'Lỗi cập nhật sản phẩm');
      res.redirect(`/admin/products/${req.params.id}/edit`);
    }
  });

// Xóa sản phẩm
router.post('/products/:id/delete', requireLogin, async (req, res) => {
  try {
    await Product.findByIdAndDelete(req.params.id);
    res.cookie('success', 'Đã xóa sản phẩm');
  } catch (err) {
    res.cookie('error', 'Lỗi xóa sản phẩm');
  }
  res.redirect('/admin/products');
});

module.exports = router; 