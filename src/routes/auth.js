const express = require('express');
const bcrypt = require('bcrypt');
const User = require('../models/User');
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');

const router = express.Router();

// JWT helper
function signToken(userId) {
  if (!process.env.JWT_SECRET) {
    throw new Error('Thiếu JWT_SECRET trong .env');
  }
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '7d' });
}

// GET đăng ký
router.get('/register', (req, res) => {
  res.render('admin/register', { title: 'Đăng ký Admin', userId: res.locals.userId });
});

// POST đăng ký
router.post('/register',
  body('username').notEmpty().withMessage('Username là bắt buộc'),
  body('password').isLength({ min: 4 }).withMessage('Mật khẩu tối thiểu 4 ký tự'),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.cookie('error', errors.array().map(e => e.msg).join('. '));
      return res.redirect('/auth/register');
    }
    const { username, password } = req.body;
    try {
      const existing = await User.findOne({ username });
      if (existing) {
        res.cookie('error', 'Username đã tồn tại');
        return res.redirect('/auth/register');
      }
      const hash = await bcrypt.hash(password, 10);
      await User.create({ username, password: hash });
      res.cookie('success', 'Đăng ký thành công, hãy đăng nhập');
      res.redirect('/auth/login');
    } catch (err) {
      res.cookie('error', 'Lỗi đăng ký');
      res.redirect('/auth/register');
    }
  });

// GET đăng nhập
router.get('/login', (req, res) => {
  res.render('admin/login', { title: 'Đăng nhập Admin', userId: res.locals.userId });
});

// POST đăng nhập
router.post('/login',
  body('username').notEmpty(),
  body('password').notEmpty(),
  async (req, res) => {
    if (!process.env.JWT_SECRET) {
      res.cookie('error', 'Thiếu JWT_SECRET trong .env');
      return res.redirect('/auth/login');
    }
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.cookie('error', 'Vui lòng nhập đầy đủ thông tin');
      return res.redirect('/auth/login');
    }
    const { username, password } = req.body;
    try {
      const user = await User.findOne({ username });
      if (!user) {
        res.cookie('error', 'Sai username hoặc mật khẩu');
        return res.redirect('/auth/login');
      }
      const match = await bcrypt.compare(password, user.password);
      if (!match) {
        res.cookie('error', 'Sai username hoặc mật khẩu');
        return res.redirect('/auth/login');
      }
      // Tạo JWT và lưu vào cookie httpOnly
      const token = signToken(user._id);
      res.cookie('token', token, {
        httpOnly: true,
        maxAge: 1000 * 60 * 60 * 24 * 7, // 7 ngày
        sameSite: 'lax',
        secure: false // true nếu dùng https
      });
      res.redirect('/admin/products');
    } catch (err) {
      res.cookie('error', 'Lỗi đăng nhập');
      res.redirect('/auth/login');
    }
  });

// GET đăng xuất
router.get('/logout', (req, res) => {
  res.clearCookie('token');
  res.redirect('/auth/login');
});

module.exports = router; 